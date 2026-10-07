defmodule HomepagePhoenix.Blog.ImageStorageTest do
  use HomepagePhoenix.DataCase, async: true

  alias HomepagePhoenix.Blog.ImageStorage

  describe "store/2（R2 未設定 → ローカルフォールバック）" do
    test "ファイルが保存され /uploads の URL が返る" do
      assert {:ok, url} = ImageStorage.store("image-bytes", ".png")
      assert String.starts_with?(url, "/uploads/")
      assert String.ends_with?(url, ".png")

      stored =
        Path.join(Application.get_env(:homepage_phoenix, :upload_dir), Path.basename(url))

      assert File.read!(stored) == "image-bytes"
    end

    test "呼び出しのたびに別のファイル名になる" do
      assert {:ok, url1} = ImageStorage.store("a", ".png")
      assert {:ok, url2} = ImageStorage.store("b", ".png")
      assert url1 != url2
    end
  end
end
