defmodule HomepagePhoenix.Blog.SeoTest do
  use ExUnit.Case, async: true

  alias HomepagePhoenix.Blog.Seo
  alias HomepagePhoenix.Blog.Post
  alias HomepagePhoenixWeb.Endpoint

  describe "document_title/1" do
    test "shortcode を除去する" do
      assert Seo.document_title("笑顔 :smile: の話") == "笑顔 の話"
    end

    test "連続空白を畳み込んで trim する" do
      assert Seo.document_title("  a   b\n\t c  ") == "a b c"
    end

    test "shortcode のみだと site_name にフォールバック" do
      assert Seo.document_title(":smile:") == Seo.site_name()
    end
  end

  describe "description_from_body/1" do
    test "Markdown 記号を除去してプレーンテキストにする" do
      assert Seo.description_from_body("# 見出し\n\n**強調** と [リンク](https://example.com)") ==
               "見出し 強調 と リンク"
    end

    test "画像行を除去する" do
      assert Seo.description_from_body("![alt](/uploads/a.png)\n\n本文") == "本文"
    end

    test "150文字超は 150文字＋… に切り詰める" do
      result = Seo.description_from_body(String.duplicate("あ", 200))
      assert String.length(result) == 151
      assert String.starts_with?(result, String.duplicate("あ", 150))
      assert String.ends_with?(result, "…")
    end

    test "150文字ちょうどは … を付けない" do
      assert Seo.description_from_body(String.duplicate("あ", 150)) == String.duplicate("あ", 150)
    end

    test "空本文は空文字" do
      assert Seo.description_from_body("") == ""
    end

    test "非 binary は空文字" do
      assert Seo.description_from_body(nil) == ""
    end
  end

  describe "first_image_url/1" do
    test "最初の画像 URL を返す" do
      assert Seo.first_image_url("![a](/uploads/1.png)\n![b](/uploads/2.png)") ==
               "/uploads/1.png"
    end

    test "画像なしは nil" do
      assert Seo.first_image_url("本文のみ") == nil
    end

    test "非 binary は nil" do
      assert Seo.first_image_url(nil) == nil
    end
  end

  describe "absolute_url/1" do
    test "相対パスを Endpoint ベースの絶対 URL にする" do
      assert Seo.absolute_url("/posts/hello") == Endpoint.url() <> "/posts/hello"
    end

    test "先頭スラッシュなしでも正しく結合する" do
      assert Seo.absolute_url("posts/hello") == Endpoint.url() <> "/posts/hello"
    end

    test "http(s) の URL はそのまま" do
      assert Seo.absolute_url("https://example.com/x.png") == "https://example.com/x.png"
      assert Seo.absolute_url("http://example.com/x.png") == "http://example.com/x.png"
    end
  end

  describe "article_json_ld/2" do
    test "必須キーが揃う" do
      post = %Post{
        title: "記事タイトル",
        body_md: "本文",
        published_at: ~U[2026-08-01 00:00:00Z],
        updated_at: ~U[2026-08-02 00:00:00Z]
      }

      json = Seo.article_json_ld(post, "https://example.com/posts/a")

      assert json["@type"] == "BlogPosting"
      assert json["headline"] == "記事タイトル"
      assert json["datePublished"] == "2026-08-01T00:00:00Z"
      assert json["dateModified"] == "2026-08-02T00:00:00Z"
      assert json["description"] == "本文"
      assert json["mainEntityOfPage"]["@id"] == "https://example.com/posts/a"
      assert json["author"]["name"] == "Johmaru"
      refute Map.has_key?(json, "image")
    end

    test "published_at が nil なら datePublished を入れない" do
      post = %Post{
        title: "t",
        body_md: "",
        published_at: nil,
        updated_at: ~U[2026-08-02 00:00:00Z]
      }

      json = Seo.article_json_ld(post, "https://example.com/posts/a")
      refute Map.has_key?(json, "datePublished")
    end

    test "先頭画像があれば絶対 URL の image 配列を追加する" do
      post = %Post{
        title: "t",
        body_md: "![x](/uploads/a.png)",
        published_at: ~U[2026-08-01 00:00:00Z],
        updated_at: ~U[2026-08-02 00:00:00Z]
      }

      json = Seo.article_json_ld(post, "https://example.com/posts/a")
      assert json["image"] == [Endpoint.url() <> "/uploads/a.png"]
    end
  end
end
