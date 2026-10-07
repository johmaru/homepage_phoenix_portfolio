defmodule HomepagePhoenix.BlogTest do
  use HomepagePhoenix.DataCase, async: true

  alias HomepagePhoenix.Blog
  alias HomepagePhoenix.Blog.Post
  alias HomepagePhoenix.AccountsFixtures

  describe "slugify/1" do
    test "ASCII タイトルを slug に変換する" do
      assert Blog.slugify("My First Post") == "my-first-post"
    end

    test "連続スペース・ハイフンを1つにまとめる" do
      assert Blog.slugify("Hello   --   World") == "hello-world"
    end

    test "日本語を含むと空文字を返す" do
      assert Blog.slugify("日本語のタイトル") == ""
    end

    test "記号を除去する" do
      assert Blog.slugify("Hello, World!!!") == "hello-world"
    end
  end

  describe "create_post/2" do
    setup do
      user = AccountsFixtures.user_fixture()
      scope = AccountsFixtures.user_scope_fixture(user)
      {:ok, user: user, scope: scope}
    end

    test "正常系: 公開投稿を作成できる", %{scope: scope} do
      attrs = valid_post_attrs()

      assert {:ok, %Post{} = post} = Blog.create_post(scope, attrs)
      assert post.title == attrs["title"]
      assert post.slug == attrs["slug"]
      assert post.body_md == attrs["body_md"]
      assert post.status == "published"
      assert post.published_at
      assert post.user_id == scope.user.id
    end

    test "異常系: title が空だとエラー", %{scope: scope} do
      attrs = valid_post_attrs(%{"title" => ""})

      assert {:error, changeset} = Blog.create_post(scope, attrs)
      assert changeset.errors[:title]
    end

    test "異常系: slug が空だとエラー", %{scope: scope} do
      attrs = valid_post_attrs(%{"slug" => ""})

      assert {:error, changeset} = Blog.create_post(scope, attrs)
      assert changeset.errors[:slug]
    end

    test "異常系: slug の形式が不正だとエラー", %{scope: scope} do
      attrs = valid_post_attrs(%{"slug" => "Invalid Slug!"})

      assert {:error, changeset} = Blog.create_post(scope, attrs)
      assert changeset.errors[:slug]
    end

    test "異常系: slug が短すぎるとエラー", %{scope: scope} do
      attrs = valid_post_attrs(%{"slug" => "ab"})

      assert {:error, changeset} = Blog.create_post(scope, attrs)
      assert changeset.errors[:slug]
    end

    test "異常系: published で published_at がないとエラー", %{scope: scope} do
      attrs =
        valid_post_attrs(%{
          "status" => "published",
          "published_at" => nil
        })

      assert {:error, changeset} = Blog.create_post(scope, attrs)
      assert changeset.errors[:published_at]
    end

    test "タグを付けて作成できる", %{scope: scope} do
      attrs = valid_post_attrs(%{"tags" => ["elixir", "phoenix"]})

      assert {:ok, post} = Blog.create_post(scope, attrs)
      assert Enum.count(post.tags) == 2
      assert Enum.map(post.tags, & &1.name) |> Enum.sort() == ["elixir", "phoenix"]
    end

    test "user_id は attrs から上書きできない", %{scope: scope} do
      other_user = AccountsFixtures.user_fixture()

      attrs =
        valid_post_attrs(%{
          "user_id" => other_user.id
        })

      assert {:ok, post} = Blog.create_post(scope, attrs)
      assert post.user_id == scope.user.id
    end
  end

  describe "list_posts/1" do
    setup do
      user = AccountsFixtures.user_fixture()
      scope = AccountsFixtures.user_scope_fixture(user)
      {:ok, user: user, scope: scope}
    end

    test "draft を除外する", %{scope: scope} do
      _draft = create_draft_post(scope)
      published = create_published_post(scope)

      result = Blog.list_posts(page: 1)
      assert Enum.map(result.posts, & &1.id) == [published.id]
    end

    test "未来の published_at を除外する", %{scope: scope} do
      future = create_post(scope, %{"status" => "published", "published_at" => future_iso()})
      _published = create_published_post(scope)

      result = Blog.list_posts(page: 1)
      refute Enum.any?(result.posts, &(&1.id == future.id))
    end

    test "published_at DESC で並ぶ", %{scope: scope} do
      older = create_published_post(scope, %{"slug" => "older-post"})
      newer = create_published_post(scope, %{"slug" => "newer-post"})

      result = Blog.list_posts(page: 1)
      assert Enum.map(result.posts, & &1.id) == [newer.id, older.id]
    end

    test "ページング情報を返す", %{scope: scope} do
      for i <- 1..12 do
        create_published_post(scope, %{"slug" => "post-#{i}"})
      end

      result = Blog.list_posts(page: 1)
      assert result.page == 1
      assert result.total_pages == 2
      assert length(result.posts) == 10
    end

    test "page が1未満なら1にフォールバック", %{scope: scope} do
      create_published_post(scope)
      result = Blog.list_posts(page: 0)
      assert result.page == 1
    end

    test "page が total_pages を超える場合は最大値にクランプ", %{scope: scope} do
      create_published_post(scope)
      result = Blog.list_posts(page: 99)
      assert result.page == 1
    end
  end

  describe "get_post_by_slug!/1" do
    setup do
      user = AccountsFixtures.user_fixture()
      scope = AccountsFixtures.user_scope_fixture(user)
      {:ok, user: user, scope: scope}
    end

    test "公開済み slug を取得できる", %{scope: scope} do
      post = create_published_post(scope, %{"slug" => "my-post"})
      assert Blog.get_post_by_slug!("my-post").id == post.id
    end

    test "draft は 404 を raise", %{scope: scope} do
      create_draft_post(scope, %{"slug" => "draft-post"})

      assert_raise Ecto.NoResultsError, fn ->
        Blog.get_post_by_slug!("draft-post")
      end
    end

    test "未来の published_at は 404 を raise", %{scope: scope} do
      create_post(scope, %{
        "slug" => "future-post",
        "status" => "published",
        "published_at" => future_iso()
      })

      assert_raise Ecto.NoResultsError, fn ->
        Blog.get_post_by_slug!("future-post")
      end
    end
  end

  describe "tags" do
    test "ensure_tags は存在しないものを作成する" do
      {:ok, _} = Blog.create_tag(%{name: "existing"})

      tags = Blog.ensure_tags(["existing", "new1", "new2"])
      names = Enum.map(tags, & &1.name) |> Enum.sort()
      assert names == ["existing", "new1", "new2"]
    end

    test "ensure_tags は重複を排除する" do
      tags = Blog.ensure_tags(["dup", "dup", "dup"])
      assert length(tags) == 1
    end
  end

  describe "Renderer" do
    alias HomepagePhoenix.Blog.Renderer

    test "to_toc の anchor が to_html の id と一致する（CJK 含む）" do
      body_md = """
      # メインタイトル

      ## はじめに

      本文

      ### 日本語サブセクション

      本文

      ## English Section
      """

      html = Renderer.to_html(body_md)
      toc = Renderer.to_toc(body_md)

      assert Enum.map(toc, & &1.anchor) == extract_ids(html)
      assert Enum.any?(toc, &(&1.text =~ "はじめに"))
      assert Enum.any?(toc, &(&1.text =~ "日本語サブセクション"))
      assert Enum.any?(toc, &(&1.text =~ "English Section"))
    end

    test "to_toc は H2/H3 のレベルを正しく判定する" do
      body_md = "## H2\n\n本文\n\n### H3\n"
      toc = Renderer.to_toc(body_md)
      assert Enum.map(toc, & &1.level) == [2, 3]
    end
  end

  # ヘルパー

  defp valid_post_attrs(overrides \\ %{}) do
    slug = "post-#{System.unique_integer([:positive])}"

    %{
      "title" => "テスト投稿",
      "slug" => slug,
      "body_md" => "# Hello\n本文です",
      "status" => "published",
      "published_at" => DateTime.utc_now() |> DateTime.to_iso8601()
    }
    |> Map.merge(overrides)
  end

  defp extract_ids(html) do
    Regex.compile!(~S|<h[23]\s+id="([^"]+)"|, "")
    |> Regex.scan(html, capture: :all_but_first)
    |> List.flatten()
  end

  defp create_published_post(scope, overrides \\ %{}) do
    attrs =
      valid_post_attrs(overrides)
      |> Map.put("status", "published")
      |> Map.put("published_at", DateTime.utc_now() |> DateTime.to_iso8601())

    {:ok, post} = Blog.create_post(scope, attrs)
    post
  end

  defp create_draft_post(scope, overrides \\ %{}) do
    attrs =
      valid_post_attrs(overrides)
      |> Map.put("status", "draft")
      |> Map.delete("published_at")

    {:ok, post} = Blog.create_post(scope, attrs)
    post
  end

  defp create_post(scope, overrides) do
    {:ok, post} = Blog.create_post(scope, valid_post_attrs(overrides))
    post
  end

  defp future_iso do
    DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.to_iso8601()
  end
end
