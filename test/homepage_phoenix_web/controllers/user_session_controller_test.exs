defmodule HomepagePhoenixWeb.UserSessionLiveTest do
  # async: false が必要。UserLoginConfirmationLive が接続済み LiveView の
  # mount 中に handle_params で DB クエリを実行するため。async: true では
  # LiveView プロセスがテストのサンドボックストランザクションを参照できない。
  use HomepagePhoenixWeb.ConnCase, async: false
  import Ecto.Query

  import HomepagePhoenix.AccountsFixtures
  alias HomepagePhoenix.Accounts

  setup do
    %{unconfirmed_user: unconfirmed_user_fixture(), user: user_fixture()}
  end

  describe "GET /users/log-in" do
    test "renders login page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/users/log-in")

      assert html =~ "Log in"
      assert html =~ ~p"/users/register"
      assert html =~ "Log in with email"
    end

    test "redirects logged in user to home page", %{conn: conn, user: user} do
      # ログイン済みユーザーが /users/log-in にアクセスすると、
      # redirect_if_user_is_authenticated on_mount コールバックによって
      # ホームページにリダイレクトされる。
      {:error, {:redirect, %{to: to}}} =
        conn
        |> log_in_user(user)
        |> live(~p"/users/log-in")

      assert to == ~p"/"
    end

    test "renders login page (email + password)", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/users/log-in")

      assert has_element?(view, "#login_form_magic")
      assert has_element?(view, "#login_form_password")
    end

    test "renders both login forms", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/users/log-in")

      assert has_element?(view, "#login_form_magic")
      assert has_element?(view, "#login_form_password")
    end
  end

  describe "GET /users/log-in/:token" do
    test "renders confirmation page for unconfirmed user", %{
      conn: conn,
      unconfirmed_user: user
    } do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_login_instructions(user, url)
        end)

      {:ok, view, _html} = live(conn, ~p"/users/log-in/#{token}")

      # 未確認ユーザーにはアカウント確認を完了するための確認フォームが表示される。
      assert has_element?(view, "#confirmation_form")
      assert has_element?(view, "button", "Confirm and stay logged in")
    end

    test "renders login page for confirmed user", %{conn: conn, user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_login_instructions(user, url)
        end)

      {:ok, view, _html} = live(conn, ~p"/users/log-in/#{token}")

      # 確認済みユーザーにはログインを完了するためのログインフォームが表示される。
      assert has_element?(view, "#login_form")
    end

    test "redirects to log in for invalid token", %{conn: conn} do
      {:error, {:live_redirect, %{to: to, flash: flash}}} =
        live(conn, ~p"/users/log-in/invalid-token")

      assert to == ~p"/users/log-in"
      assert flash["error"] == "Magic link is invalid or it has expired."
    end
  end

  describe "POST /users/log-in - email and password" do
    test "logs the user in", %{conn: conn, user: user} do
      user = set_password(user)

      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{"email" => user.email, "password" => valid_user_password()}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/"

      # ログイン済みリクエストを行いメニューを検証（ヘッダーにはユーザー名が表示される）
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ user.username
      assert response =~ ~p"/users/settings"
      assert response =~ ~p"/users/log-out"
    end

    test "logs the user in with remember me", %{conn: conn, user: user} do
      user = set_password(user)

      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{
            "email" => user.email,
            "password" => valid_user_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_homepage_phoenix_web_user_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the user in with return to", %{conn: conn, user: user} do
      user = set_password(user)

      conn =
        conn
        |> init_test_session(user_return_to: "/foo/bar")
        |> post(~p"/users/log-in", %{
          "user" => %{
            "email" => user.email,
            "password" => valid_user_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "emits error message with invalid credentials", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/users/log-in?mode=password", %{
          "user" => %{"email" => user.email, "password" => "invalid_password"}
        })

      # コントローラーはログインページにリダイレクトする（200 レンダリングはしない）。
      assert redirected_to(conn) == ~p"/users/log-in"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Invalid email or password"
    end
  end

  describe "POST /users/log-in - magic link" do
    test "sends magic link email when user exists", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{"email" => user.email}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"
      assert HomepagePhoenix.Repo.get_by!(Accounts.UserToken, user_id: user.id).context == "login"
    end

    test "logs the user in", %{conn: conn, user: user} do
      {token, _hashed_token} = generate_user_magic_link_token(user)

      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{"token" => token}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/"

      # ログイン済みリクエストを行いメニューを検証（ヘッダーにはユーザー名が表示される）
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ user.username
      assert response =~ ~p"/users/settings"
      assert response =~ ~p"/users/log-out"
    end

    test "confirms unconfirmed user", %{conn: conn} do
      # login_user_by_magic_link/1 はパスワード設定済みの未確認ユーザーを拒否する
      # （セッション固定攻撃対策）。ユーザーを登録した後、hashed_password を
      # クリアしてマジックリンク確認を許可する。
      user = unconfirmed_user_fixture()

      HomepagePhoenix.Repo.update_all(
        from(u in Accounts.User, where: u.id == ^user.id),
        set: [hashed_password: nil]
      )

      {token, _hashed_token} = generate_user_magic_link_token(user)
      refute user.confirmed_at

      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{"token" => token},
          "_action" => "confirmed"
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "User confirmed successfully."

      assert Accounts.get_user!(user.id).confirmed_at

      # ログイン済みリクエストを行いメニューを検証（ヘッダーにはユーザー名が表示される）
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ user.username
      assert response =~ ~p"/users/settings"
      assert response =~ ~p"/users/log-out"
    end

    test "emits error message when magic link is invalid", %{conn: conn} do
      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{"token" => "invalid"}
        })

      assert redirected_to(conn) == ~p"/users/log-in"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "The link is invalid or it has expired."
    end
  end

  describe "DELETE /users/log-out" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(~p"/users/log-out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/users/log-out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
