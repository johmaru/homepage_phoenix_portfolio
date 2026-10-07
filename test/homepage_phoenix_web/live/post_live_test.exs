defmodule HomepagePhoenixWeb.PostLiveTest do
  # async: false が必要。LiveView プロセスの mount / handle_params 内で
  # DB クエリを実行するため、async: true ではサンドボックスのトランザクションを
  # 参照できず 404 や認証失敗になる。
  use HomepagePhoenixWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias HomepagePhoenix.Blog
  alias HomepagePhoenix.AccountsFixtures
  alias HomepagePhoenix.Emojis
  alias HomepagePhoenixWeb.Endpoint

  describe "PostLive /posts" do
    test "公開済み投稿のみ表示される", %{conn: conn} do
      user = AccountsFixtures.user_fixture()
      scope = AccountsFixtures.user_scope_fixture(user)

      published =
        create_published_post(scope, %{"title" => "公開済みタイトル", "slug" => "published-post"})

      _draft = create_draft_post(scope, %{"title" => "下書きタイトル", "slug" => "draft-post"})

      {:ok, view, _html} = live(conn, ~p"/posts")

      assert has_element?(view, "#post-card-#{published.id}")
      refute has_element?(view, "#post-card-#{_draft.id}")
    end

    test "ページングのリンクが表示される", %{conn: conn} do
      user = AccountsFixtures.user_fixture()
      scope = AccountsFixtures.user_scope_fixture(user)

      for i <- 1..12 do
        create_published_post(scope, %{"slug" => "post-#{i}", "title" => "Post #{i}"})
      end

      {:ok, view, _html} = live(conn, ~p"/posts")
      assert has_element?(view, "a[href='/posts?page=2']")
    end
  end

  describe "PostShowLive /posts/:slug" do
    test "本文 HTML が描画される", %{conn: conn} do
      user = AccountsFixtures.user_fixture()
      scope = AccountsFixtures.user_scope_fixture(user)

      post =
        create_published_post(scope, %{
          "slug" => "hello-world",
          "title" => "Hello World",
          "body_md" => "# Hello\n\nWorld"
        })

      {:ok, view, _html} = live(conn, ~p"/posts/#{post.slug}")
      assert has_element?(view, "#post-body h1")
    end

    test "タイトル・本文のカスタム絵文字が画像表示される", %{conn: conn} do
      user = AccountsFixtures.user_fixture()
      scope = AccountsFixtures.user_scope_fixture(user)

      {:ok, _} =
        Emojis.create_emoji(scope, %{"name" => "smile", "image_url" => "/uploads/smile.png"})

      post =
        create_published_post(scope, %{
          "slug" => "emoji-post",
          "title" => "笑顔 :smile:",
          "body_md" => "本文 :smile:"
        })

      {:ok, view, html} = live(conn, ~p"/posts/#{post.slug}")

      assert html =~ ~s(<h1 class="text-3xl font-bold tracking-tight">)
      assert html =~ ~s(<img class="custom-emoji" src="/uploads/smile.png" alt=":smile:")
      assert has_element?(view, "#post-body img.custom-emoji")
    end

    test "TOC が H2/H3 から生成される", %{conn: conn} do
      user = AccountsFixtures.user_fixture()
      scope = AccountsFixtures.user_scope_fixture(user)

      post =
        create_published_post(scope, %{
          "slug" => "toc-post",
          "title" => "TOC Post",
          "body_md" => "## セクション1\n\n本文\n\n### サブセクション\n\n本文"
        })

      {:ok, view, _html} = live(conn, ~p"/posts/#{post.slug}")
      assert has_element?(view, "aside nav a")
    end
  end

  describe "Admin.PostIndexLive /admin/posts" do
    test "未認証アクセスでログインページにリダイレクト", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(conn, ~p"/admin/posts")
    end

    test "非管理者はリダイレクト", %{conn: conn} do
      user = AccountsFixtures.user_fixture()
      conn = log_in_user(conn, user)

      assert {:error, {:live_redirect, %{to: "/"}}} = live(conn, ~p"/admin/posts")
    end

    test "管理者は draft 含む全件表示", %{conn: conn} do
      user = AccountsFixtures.admin_user_fixture()
      scope = AccountsFixtures.user_scope_fixture(user)
      conn = log_in_user(conn, user)

      published = create_published_post(scope, %{"slug" => "admin-pub", "title" => "Admin Pub"})
      draft = create_draft_post(scope, %{"slug" => "admin-draft", "title" => "Admin Draft"})

      {:ok, view, _html} = live(conn, ~p"/admin/posts")

      assert has_element?(view, "#admin-posts tr##{dom_id(published)}")
      assert has_element?(view, "#admin-posts tr##{dom_id(draft)}")
    end
  end

  describe "Admin.PostFormLive /admin/posts/new" do
    test "管理者はフォームが表示される", %{conn: conn} do
      user = AccountsFixtures.admin_user_fixture()
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/admin/posts/new")
      assert has_element?(view, "#post-form")
      assert has_element?(view, "#publish-btn")
      assert has_element?(view, "#preview-btn")
    end

    test "公開ボタンで status=published になる", %{conn: conn} do
      user = AccountsFixtures.admin_user_fixture()
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/admin/posts/new")

      # フォームに入力して validate を発火（changeset を更新）
      view
      |> form("#post-form", %{
        "post" => %{
          "title" => "新規公開",
          "slug" => "new-published",
          "body_md" => "# 本文",
          "tags" => "tag1,tag2"
        }
      })
      |> render_change()

      # publish ボタン（type="button" phx-click="publish"）をクリック
      view |> element("#publish-btn") |> render_click()

      # 保存後は /admin/posts にナビゲート
      assert_redirect(view, ~p"/admin/posts")

      post = Blog.get_admin_post_by_slug!("new-published")
      assert post.status == "published"
      assert post.published_at
      assert Enum.count(post.tags) == 2
    end
  end

  describe "Admin.PostFormLive 画像アップロード" do
    test "アップロードした画像の URL が本文に挿入され、ファイルが保存される", %{conn: conn} do
      user = AccountsFixtures.admin_user_fixture()
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/admin/posts/new")

      upload =
        file_input(view, "#post-form", :image, [
          %{name: "photo.png", content: "fake png content", type: "image/png"}
        ])

      # アップロード完了で挿入ボタンが表示される
      assert render_upload(upload, "photo.png") =~ "insert-image-btn"

      view |> element("#insert-image-btn") |> render_click()

      html = render(view)
      assert [_, url] = Regex.run(~r{(/uploads/[^\s"'<>()]+)}, html)
      assert html =~ "![](#{url})"

      # ファイルがアップロード先に実在する
      stored = Path.join(Application.get_env(:homepage_phoenix, :upload_dir), Path.basename(url))
      assert File.exists?(stored)
      assert File.read!(stored) == "fake png content"
    end

    test "許可されていない形式はエラー表示される", %{conn: conn} do
      user = AccountsFixtures.admin_user_fixture()
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/admin/posts/new")

      upload =
        file_input(view, "#post-form", :image, [
          %{name: "note.txt", content: "plain text", type: "text/plain"}
        ])

      # 許可外形式はアップロード自体が拒否される
      assert {:error, [[_ref, :not_accepted]]} = render_upload(upload, "note.txt")

      html = render(view)
      assert html =~ "対応していない形式です"
      refute has_element?(view, "#insert-image-btn")
    end

    test "本文を入力済みなら、その後に画像マークダウンが追記される", %{conn: conn} do
      user = AccountsFixtures.admin_user_fixture()
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/admin/posts/new")

      view
      |> form("#post-form", %{"post" => %{"body_md" => "# 本文あり"}})
      |> render_change()

      upload =
        file_input(view, "#post-form", :image, [
          %{name: "pic.webp", content: "webp bytes", type: "image/webp"}
        ])

      render_upload(upload, "pic.webp")
      view |> element("#insert-image-btn") |> render_click()

      html = render(view)
      assert html =~ "# 本文あり"
      assert html =~ "![](/uploads/"
    end
  end

  describe "SEO メタ" do
    test "投稿ページに title/description/OG/JSON-LD が出力される", %{conn: conn} do
      user = AccountsFixtures.user_fixture()
      scope = AccountsFixtures.user_scope_fixture(user)

      post =
        create_published_post(scope, %{
          "slug" => "seo-post",
          "title" => "Hello World",
          "body_md" => "# 見出し\n\n本文の説明文。"
        })

      html = get(conn, ~p"/posts/#{post.slug}") |> html_response(200)

      assert html =~ "<title"
      assert html =~ "Hello World"
      assert html =~ ~s(meta name="description")
      assert html =~ ~s(property="og:type" content="article")
      assert html =~ "application/ld+json"
      assert html =~ ~s("headline":"Hello World")
      assert html =~ ~s("@type":"BlogPosting")
    end

    test "本文画像があると og:image が絶対 URL になる", %{conn: conn} do
      user = AccountsFixtures.user_fixture()
      scope = AccountsFixtures.user_scope_fixture(user)

      post =
        create_published_post(scope, %{
          "slug" => "seo-image-post",
          "title" => "Image Post",
          "body_md" => "![x](/uploads/a.png)\n\n本文"
        })

      html = get(conn, ~p"/posts/#{post.slug}") |> html_response(200)

      assert html =~ ~s(property="og:image" content="#{Endpoint.url()}/uploads/a.png")
      assert html =~ ~s(name="twitter:card" content="summary_large_image")
    end

    test "画像なしでは og:image が出力されず twitter:card は summary", %{conn: conn} do
      user = AccountsFixtures.user_fixture()
      scope = AccountsFixtures.user_scope_fixture(user)

      post =
        create_published_post(scope, %{
          "slug" => "seo-no-image-post",
          "title" => "No Image Post",
          "body_md" => "本文のみ"
        })

      html = get(conn, ~p"/posts/#{post.slug}") |> html_response(200)

      refute html =~ ~s(property="og:image")
      assert html =~ ~s(name="twitter:card" content="summary")
    end

    test "一覧ページは一覧用メタと canonical /posts が出力される", %{conn: conn} do
      html = get(conn, ~p"/posts") |> html_response(200)

      assert html =~ "投稿一覧"
      assert html =~ ~s(rel="canonical" href="#{Endpoint.url()}/posts")
      assert html =~ ~s(property="og:type" content="website")
      refute html =~ "application/ld+json"
    end

    test "タグ一覧はタグ用メタと canonical /posts/tag/:tag が出力される", %{conn: conn} do
      user = AccountsFixtures.user_fixture()
      scope = AccountsFixtures.user_scope_fixture(user)

      create_published_post(scope, %{
        "slug" => "tagged-post",
        "title" => "Tagged",
        "tags" => ["elixir"]
      })

      html = get(conn, ~p"/posts/tag/elixir") |> html_response(200)

      assert html =~ "タグ: elixir"
      assert html =~ ~s(rel="canonical" href="#{Endpoint.url()}/posts/tag/elixir")
    end
  end

  # ヘルパー

  defp create_published_post(scope, overrides) do
    slug = "post-#{System.unique_integer([:positive])}"

    attrs =
      %{
        "title" => "Title",
        "slug" => slug,
        "body_md" => "# Hello",
        "status" => "published",
        "published_at" => DateTime.utc_now() |> DateTime.to_iso8601()
      }
      |> Map.merge(overrides)

    {:ok, post} = Blog.create_post(scope, attrs)
    post
  end

  defp create_draft_post(scope, overrides) do
    slug = "draft-#{System.unique_integer([:positive])}"

    attrs =
      %{
        "title" => "Draft",
        "slug" => slug,
        "body_md" => "# Draft",
        "status" => "draft"
      }
      |> Map.merge(overrides)

    {:ok, post} = Blog.create_post(scope, attrs)
    post
  end

  defp dom_id(%HomepagePhoenix.Blog.Post{id: id}), do: "posts-#{id}"
end
