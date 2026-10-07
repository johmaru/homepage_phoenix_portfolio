defmodule HomepagePhoenixWeb.UserAuth do
  use HomepagePhoenixWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias HomepagePhoenix.Accounts
  alias HomepagePhoenix.Accounts.Scope

  # remember me Cookie の有効期限を 14 日にする。UserToken の
  # セッション有効期限設定と一致させる必要がある。
  @max_cookie_age_in_days 14
  @remember_me_cookie "_homepage_phoenix_web_user_remember_me"
  @remember_me_options [
    sign: true,
    max_age: @max_cookie_age_in_days * 24 * 60 * 60,
    same_site: "Lax"
  ]

  # セッショントークンが新しいものに再発行されるまでの経過日数。
  # この値より古いセッショントークンでリクエストが行われた場合、新しいセッショントークンが
  # 作成され、セッションおよび remember-me Cookie（設定されていれば）が新しいトークンで更新される。
  # この値を下げるとアクティブユーザーのトークン作成回数が増える。上げると、セッショントークンが
  # 期限切れになるまでの時間が短くなり、新しいトークンが発行される。
  # `@max_cookie_age_in_days` より大きい値を設定すると、トークンの再発行を完全に無効化できる。
  @session_reissue_age_in_days 7

  @doc """
  ユーザーをログインさせる。

  セッションの `:user_return_to` パスにリダイレクトする。
  または `signed_in_path/1` にフォールバックする。
  """
  def log_in_user(conn, user, params \\ %{}) do
    user_return_to = get_session(conn, :user_return_to)

    conn
    |> create_or_extend_session(user, params)
    |> redirect(to: user_return_to || signed_in_path(conn))
  end

  @doc """
  ユーザーをログアウトさせる。

  安全のためすべてのセッションデータを消去する。renew_session を参照。
  """
  def log_out_user(conn) do
    user_token = get_session(conn, :user_token)
    user_token && Accounts.delete_user_session_token(user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      HomepagePhoenixWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session(nil)
    |> delete_resp_cookie(@remember_me_cookie, @remember_me_options)
    |> redirect(to: ~p"/")
  end

  @doc """
  セッションと remember-me トークンからユーザーを認証する。

  セッショントークンが設定された経過日数を超えている場合は再発行する。
  """
  def fetch_current_scope_for_user(conn, _opts) do
    with {token, conn} <- ensure_user_token(conn),
         {user, token_inserted_at} <- Accounts.get_user_by_session_token(token) do
      conn
      |> assign(:current_scope, Scope.for_user(user))
      |> maybe_reissue_user_session_token(user, token_inserted_at)
    else
      nil -> assign(conn, :current_scope, Scope.for_user(nil))
    end
  end

  defp ensure_user_token(conn) do
    if token = get_session(conn, :user_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if token = conn.cookies[@remember_me_cookie] do
        {token, conn |> put_token_in_session(token) |> put_session(:user_remember_me, true)}
      else
        nil
      end
    end
  end

  # セッショントークンが再発行経過日数を超えている場合に再発行する。
  defp maybe_reissue_user_session_token(conn, user, token_inserted_at) do
    token_age = DateTime.diff(DateTime.utc_now(:second), token_inserted_at, :day)

    if token_age >= @session_reissue_age_in_days do
      create_or_extend_session(conn, user, %{})
    else
      conn
    end
  end

  # この関数はセッショントークンを作成し、セッションと Cookie に安全に
  # 保存する責任を持つ。ログイン時または期限切れ間近の
  # セッションの更新時に呼び出される。
  #
  # セッションが更新ではなく新規作成される場合、fixation 攻撃を防ぐため
  # renew_session 関数がセッションを消去する。この挙動のカスタマイズは
  # renew_session 関数を参照。
  defp create_or_extend_session(conn, user, params) do
    token = Accounts.generate_user_session_token(user)
    remember_me = get_session(conn, :user_remember_me)

    conn
    |> renew_session(user)
    |> put_token_in_session(token)
    |> maybe_write_remember_me_cookie(token, params, remember_me)
  end

  # 既にログイン済みの場合はセッションを更新しない
  # （開いたままのタブでの CSRF エラーやデータ消失を防ぐため）
  defp renew_session(conn, user) when conn.assigns.current_scope.user.id == user.id do
    conn
  end

  # この関数はセッション ID を更新し、fixation 攻撃を防ぐため
  # セッション全体を消去する。ログイン/ログアウト後に保持したい
  # セッションデータがある場合は、消去前に明示的に取得し、
  # 消去後にすぐに再設定する必要がある。例:
  #
  #     defp renew_session(conn, _user) do
  #       delete_csrf_token()
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn, _user) do
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}, _),
    do: write_remember_me_cookie(conn, token)

  defp maybe_write_remember_me_cookie(conn, token, _params, true),
    do: write_remember_me_cookie(conn, token)

  defp maybe_write_remember_me_cookie(conn, _token, _params, _), do: conn

  defp write_remember_me_cookie(conn, token) do
    conn
    |> put_session(:user_remember_me, true)
    |> put_resp_cookie(@remember_me_cookie, token, @remember_me_options)
  end

  defp put_token_in_session(conn, token) do
    put_session(conn, :user_token, token)
  end

  @doc """
  ユーザーが未認証であることを要求するルート用 Plug。
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns.current_scope do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  defp signed_in_path(_conn), do: ~p"/"

  @doc """
  認証済みユーザーを要求するルート用 Plug。
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns.current_scope && conn.assigns.current_scope.user do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/users/log-in")
      |> halt()
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  @doc """
  セッションから現在のスコープを取得する LiveView の mount コールバック。
  """
  def on_mount(:mount_current_scope, _params, session, socket) do
    {:cont, mount_current_scope(socket, session)}
  end

  # mount コールバック: ユーザーが既に認証済みの場合はリダイレクトする。
  def on_mount(:redirect_if_user_is_authenticated, _params, _session, socket) do
    if socket.assigns[:current_scope] && socket.assigns.current_scope.user do
      {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(nil))}
    else
      {:cont, socket}
    end
  end

  # mount コールバック: 認証済みユーザーを要求し、未認証ならリダイレクトする。
  def on_mount(:require_authenticated_user, _params, _session, socket) do
    if socket.assigns[:current_scope] && socket.assigns.current_scope.user do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/users/log-in")

      {:halt, socket}
    end
  end

  defp mount_current_scope(socket, session) do
    if token = session["user_token"] do
      case Accounts.get_user_by_session_token(token) do
        {user, _token_inserted_at} ->
          socket
          |> Phoenix.Component.assign(:current_scope, Scope.for_user(user))
          |> Phoenix.Component.assign_new(:current_user, fn -> user end)

        nil ->
          socket |> Phoenix.Component.assign(:current_scope, Scope.for_user(nil))
      end
    else
      socket |> Phoenix.Component.assign(:current_scope, Scope.for_user(nil))
    end
  end
end
