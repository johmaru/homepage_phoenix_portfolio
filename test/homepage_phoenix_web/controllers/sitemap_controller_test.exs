defmodule HomepagePhoenixWeb.SitemapControllerTest do
  use HomepagePhoenixWeb.ConnCase, async: false

  alias HomepagePhoenix.Blog
  alias HomepagePhoenix.Memos
  alias HomepagePhoenix.AccountsFixtures
  alias HomepagePhoenixWeb.Endpoint

  describe "GET /sitemap.xml" do
    test "静的 URL、公開投稿、公開メモの <loc> が含まれ、URL限定メモは含まれない", %{conn: conn} do
      user = AccountsFixtures.user_fixture()
      scope = AccountsFixtures.user_scope_fixture(user)
      public_memo = create_memo(scope, %{"title" => "Sitemap Memo"})
      unlisted_memo = create_memo(scope, %{"title" => "Unlisted Sitemap Memo", "visibility" => "unlisted"})

      published =
        create_post(scope, %{
          "title" => "SiteMap Post",
          "slug" => "sitemap-published",
          "body_md" => "# 公開",
          "status" => "published",
          "published_at" => DateTime.utc_now() |> DateTime.to_iso8601()
        })

      body = get(conn, ~p"/sitemap.xml") |> response(200)
      public_lastmod = public_memo.updated_at |> DateTime.to_date() |> Date.to_iso8601()


      assert body =~ "<urlset"
      assert body =~ "<loc>#{Endpoint.url()}/</loc>"
      assert body =~ "<loc>#{Endpoint.url()}/profile</loc>"
      assert body =~ "<loc>#{Endpoint.url()}/oshi</loc>"
      assert body =~ "<loc>#{Endpoint.url()}/posts</loc>"
      assert body =~ "<loc>#{Endpoint.url()}/activity</loc>"
      assert body =~ "<loc>#{Endpoint.url()}/memos</loc>"
      assert body =~ "<loc>#{Endpoint.url()}/memos/#{public_memo.share_id}</loc>"

      assert body =~
               "<loc>#{Endpoint.url()}/memos/#{public_memo.share_id}</loc><lastmod>#{public_lastmod}</lastmod>"
      refute body =~ "<loc>#{Endpoint.url()}/memos/#{unlisted_memo.share_id}</loc>"
      assert body =~ "<loc>#{Endpoint.url()}/posts/#{published.slug}</loc>"
      assert body =~ "<loc>#{Endpoint.url()}/posts/#{published.slug}</loc><lastmod>"
    end

    test "draft と未来の published_at は含まれない", %{conn: conn} do
      user = AccountsFixtures.user_fixture()
      scope = AccountsFixtures.user_scope_fixture(user)

      draft = create_post(scope, %{"title" => "Draft", "slug" => "sitemap-draft"})

      future =
        create_post(scope, %{
          "title" => "Future",
          "slug" => "sitemap-future",
          "status" => "published",
          "published_at" => DateTime.add(DateTime.utc_now(), 3600) |> DateTime.to_iso8601()
        })

      body = get(conn, ~p"/sitemap.xml") |> response(200)

      refute body =~ "/posts/#{draft.slug}"
      refute body =~ "/posts/#{future.slug}"
    end

    test "application/xml で配信される", %{conn: conn} do
      conn = get(conn, ~p"/sitemap.xml")
      assert response_content_type(conn, :xml)
    end
  end

  defp create_post(scope, overrides) do
    slug = "post-#{System.unique_integer([:positive])}"

    attrs =
      %{
        "title" => "Title",
        "slug" => slug,
        "body_md" => "# Hello",
        "status" => "draft"
      }
      |> Map.merge(overrides)

    {:ok, post} = Blog.create_post(scope, attrs)
    post
  end

  defp create_memo(scope, overrides) do
    attrs =
      %{
        "title" => "Sitemap memo",
        "body" => "Sitemap body",
        "visibility" => "public"
      }
      |> Map.merge(overrides)

    {:ok, memo} = Memos.create_memo(scope, attrs)
    memo
  end
end
