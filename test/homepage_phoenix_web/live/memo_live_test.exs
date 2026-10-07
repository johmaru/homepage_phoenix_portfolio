defmodule HomepagePhoenixWeb.MemoLiveTest do
  # async: false が必要。LiveView プロセスの mount / handle_event 内で
  # DB クエリを実行するため（PostLiveTest と同じ理由）。
  use HomepagePhoenixWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias HomepagePhoenix.AccountsFixtures
  alias HomepagePhoenix.Memos

  describe "MemoLive /memos" do
    test "公開一覧は public のメモだけをカード表示する", %{conn: conn} do
      public = create_memo(%{"title" => "公開メモ"})
      unlisted = create_memo(%{"title" => "限定メモ", "visibility" => "unlisted"})

      {:ok, view, _html} = live(conn, ~p"/memos")

      assert has_element?(view, "#memo-card-#{public.id}")
      assert has_element?(view, "#memo-card-#{public.id} a[href='/memos/#{public.share_id}']")
      refute has_element?(view, "#memo-card-#{unlisted.id}")
    end

    test "未認証でも public と unlisted の個別 URLを開ける", %{conn: conn} do
      public = create_memo(%{"title" => "公開メモ"})
      unlisted = create_memo(%{"title" => "限定メモ", "visibility" => "unlisted"})

      for memo <- [public, unlisted] do
        {:ok, view, _html} = live(conn, ~p"/memos/#{memo.share_id}")

        assert has_element?(view, "#memo-body")
        assert has_element?(view, "#memo-copy-controls")
      end
    end

    test "本文の HTML 風文字列とテンプレート風文字列はそのまま表示される", %{conn: conn} do
      body = "system:\n  {{variable}}\n<script>window.memoExecuted = true</script>\n# 記号もそのまま"
      memo = create_memo(%{"body" => body})

      {:ok, view, _html} = live(conn, ~p"/memos/#{memo.share_id}")
      html = get(conn, ~p"/memos/#{memo.share_id}") |> html_response(200)
      document = LazyHTML.from_document(html)
      memo_body = LazyHTML.query(document, "#memo-body")

      assert LazyHTML.text(memo_body) == body
      refute has_element?(view, "#memo-body script")
    end

    test "全文コピーのフック・対象・ステータス要素が表示される", %{conn: conn} do
      memo = create_memo()

      {:ok, view, _html} = live(conn, ~p"/memos/#{memo.share_id}")

      assert has_element?(
               view,
               "#memo-copy-controls[phx-hook='CopyText'][phx-update='ignore'][data-copy-target='memo-body']"
             )

      assert has_element?(view, "#copy-memo-button[type='button']")

      assert has_element?(
               view,
               "#copy-memo-status[data-copy-status][aria-live='polite'][aria-atomic='true']"
             )

      assert render(view) =~ "全文をコピー"
    end

    test "通常の HTTP GET は unlisted だけ noindex robots を返す", %{conn: conn} do
      public = create_memo(%{"title" => "公開メモ"})
      unlisted = create_memo(%{"title" => "限定メモ", "visibility" => "unlisted"})

      public_html = get(conn, ~p"/memos/#{public.share_id}") |> html_response(200)
      unlisted_html = get(conn, ~p"/memos/#{unlisted.share_id}") |> html_response(200)

      assert robots_content(unlisted_html) == ["noindex, nofollow"]
      assert robots_content(public_html) == []
    end
  end

  describe "Admin.MemoLive /admin/memos" do
    test "未認証では一覧と新規フォームがログインへリダイレクトされる", %{conn: conn} do
      for path <- [~p"/admin/memos", ~p"/admin/memos/new"] do
        assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(conn, path)
      end
    end

    test "非管理者では一覧と新規フォームがトップへリダイレクトされる", %{conn: conn} do
      user = AccountsFixtures.user_fixture()
      conn = log_in_user(conn, user)

      for path <- [~p"/admin/memos", ~p"/admin/memos/new"] do
        assert {:error, {:live_redirect, %{to: "/"}}} = live(conn, path)
      end
    end

    test "管理者が public と unlisted をフォーム保存でき、公開範囲が反映される", %{conn: conn} do
      admin = AccountsFixtures.admin_user_fixture()
      conn = log_in_user(conn, admin)

      {:ok, view, _html} = live(conn, ~p"/admin/memos/new")

      view
      |> form("#memo-form", %{
        "memo" => %{
          "title" => "フォーム公開メモ",
          "visibility" => "public",
          "body" => "公開本文"
        }
      })
      |> render_submit()

      assert_redirect(view, ~p"/admin/memos")
      public = find_memo_by_title!("フォーム公開メモ")

      {:ok, admin_view, _html} = live(conn, ~p"/admin/memos")
      assert has_element?(admin_view, "#memo-public-link-#{public.id}")

      {:ok, public_view, _html} = live(conn, ~p"/memos")
      assert has_element?(public_view, "#memo-card-#{public.id}")

      {:ok, view, _html} = live(conn, ~p"/admin/memos/new")

      view
      |> form("#memo-form", %{
        "memo" => %{
          "title" => "フォーム限定メモ",
          "visibility" => "unlisted",
          "body" => "限定本文"
        }
      })
      |> render_submit()

      assert_redirect(view, ~p"/admin/memos")
      unlisted = find_memo_by_title!("フォーム限定メモ")

      {:ok, admin_view, _html} = live(conn, ~p"/admin/memos")
      assert has_element?(admin_view, "#memo-public-link-#{unlisted.id}")

      {:ok, public_view, _html} = live(conn, ~p"/memos")
      refute has_element?(public_view, "#memo-card-#{unlisted.id}")

      {:ok, unlisted_view, _html} = live(conn, ~p"/memos/#{unlisted.share_id}")
      assert has_element?(unlisted_view, "#memo-body")
    end

    test "編集で visibility を切り替え、削除すると管理一覧と個別 URLから消える", %{conn: conn} do
      admin = AccountsFixtures.admin_user_fixture()
      conn = log_in_user(conn, admin)

      {:ok, view, _html} = live(conn, ~p"/admin/memos/new")

      view
      |> form("#memo-form", %{
        "memo" => %{
          "title" => "編集対象メモ",
          "visibility" => "unlisted",
          "body" => "編集対象本文"
        }
      })
      |> render_submit()

      assert_redirect(view, ~p"/admin/memos")
      memo = find_memo_by_title!("編集対象メモ")

      {:ok, edit_view, _html} = live(conn, ~p"/admin/memos/#{memo.id}/edit")
      assert has_element?(edit_view, "#memo-form")

      edit_view
      |> form("#memo-form", %{
        "memo" => %{
          "title" => memo.title,
          "visibility" => "public",
          "body" => memo.body
        }
      })
      |> render_submit()

      assert_redirect(edit_view, ~p"/admin/memos")
      assert Memos.get_admin_memo!(memo.id).visibility == "public"

      {:ok, public_view, _html} = live(conn, ~p"/memos")
      assert has_element?(public_view, "#memo-card-#{memo.id}")

      {:ok, admin_view, _html} = live(conn, ~p"/admin/memos")
      assert has_element?(admin_view, "#memo-public-link-#{memo.id}")

      admin_view
      |> element("#admin-memos button[phx-value-id='#{memo.id}']")
      |> render_click()

      refute has_element?(admin_view, "#memo-public-link-#{memo.id}")
      assert_raise Ecto.NoResultsError, fn -> Memos.get_admin_memo!(memo.id) end

      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/memos/#{memo.share_id}")
      end
    end
  end

  defp create_memo(overrides \\ %{}) do
    admin = AccountsFixtures.admin_user_fixture()
    scope = AccountsFixtures.user_scope_fixture(admin)

    attrs =
      %{
        "title" => "テストメモ",
        "body" => "メモ本文です",
        "visibility" => "public"
      }
      |> Map.merge(overrides)

    {:ok, memo} = Memos.create_memo(scope, attrs)
    memo
  end

  defp find_memo_by_title!(title) do
    Enum.find(Memos.list_admin_memos(), &(&1.title == title)) ||
      raise "memo not found: #{title}"
  end

  defp robots_content(html) do
    html
    |> LazyHTML.from_document()
    |> LazyHTML.query("meta[name='robots']")
    |> LazyHTML.attribute("content")
  end
end
