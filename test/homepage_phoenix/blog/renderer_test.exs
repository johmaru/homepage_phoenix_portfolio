defmodule HomepagePhoenix.Blog.RendererTest do
  # Emojis.shortcode_map/0 が DB を読むため DataCase を使う
  use HomepagePhoenix.DataCase, async: true

  alias HomepagePhoenix.Blog.Renderer
  alias HomepagePhoenix.AccountsFixtures
  alias HomepagePhoenix.Emojis

  describe "to_html/1" do
    test "カスタム絵文字ショートコードを画像に展開する" do
      user = AccountsFixtures.user_fixture()
      scope = AccountsFixtures.user_scope_fixture(user)

      {:ok, _} =
        Emojis.create_emoji(scope, %{"name" => "smile", "image_url" => "/uploads/smile.png"})

      html = Renderer.to_html("a :smile: b")

      assert html =~ ~s(<img class="custom-emoji" src="/uploads/smile.png")
      assert html =~ ~s(alt=":smile:")
    end

    test "未登録のショートコードはそのまま残る" do
      html = Renderer.to_html("a :nope: b")
      assert html =~ "a :nope: b"
    end
  end
end
