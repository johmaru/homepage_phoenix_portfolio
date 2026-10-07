defmodule HomepagePhoenix.Blog.ImageStorage do
  @moduledoc """
  ブログ画像の保存先を抽象化するモジュール。

  R2 の環境変数（`R2_ACCOUNT_ID` 等）がすべて揃っていれば Cloudflare R2 に
  保存して公開 URL を返す。それ以外（ローカル開発・テスト）は
  `priv/static/uploads`（または `UPLOAD_DIR` / `:upload_dir` 設定）に
  ローカル保存し、`/uploads/...` の配信 URL を返す。

  ## R2 環境変数

  - `R2_ACCOUNT_ID` - Cloudflare アカウントID
  - `R2_ACCESS_KEY_ID` / `R2_SECRET_ACCESS_KEY` - R2 API トークン
  - `R2_BUCKET` - バケット名
  - `R2_PUBLIC_BASE` - 公開 URL のベース（例: `https://pub-xxxx.r2.dev`）
  - `R2_ENDPOINT_HOST` - （任意）管轄区域固有の S3 エンドポイントホスト
    （例: `<account_id>.jap.r2.cloudflarestorage.com`）。未設定ならデフォルトの
    `<account_id>.r2.cloudflarestorage.com` を使用
  """

  require Logger

  @doc """
  画像バイナリを保存し、配信 URL を返す。
  """
  @spec store(binary(), binary()) :: {:ok, String.t()} | {:error, term()}
  def store(content, ext) when is_binary(content) and is_binary(ext) do
    cfg = r2_env()

    if r2_configured?(cfg) do
      store_r2(content, ext, cfg)
    else
      store_local(content, ext)
    end
  end

  ## R2

  defp r2_env do
    %{
      account_id: System.get_env("R2_ACCOUNT_ID"),
      access_key_id: System.get_env("R2_ACCESS_KEY_ID"),
      secret_access_key: System.get_env("R2_SECRET_ACCESS_KEY"),
      bucket: System.get_env("R2_BUCKET"),
      public_base: System.get_env("R2_PUBLIC_BASE")
    }
  end

  defp r2_configured?(cfg) do
    Enum.all?(Map.values(cfg), &is_binary/1)
  end

  defp store_r2(content, ext, cfg) do
    key = random_filename(ext)

    op =
      ExAws.S3.put_object(cfg.bucket, key, content, content_type: content_type(ext))

    opts = [
      access_key_id: cfg.access_key_id,
      secret_access_key: cfg.secret_access_key,
      region: "auto",
      scheme: "https://",
      host: System.get_env("R2_ENDPOINT_HOST") || "#{cfg.account_id}.r2.cloudflarestorage.com"
    ]

    case ExAws.request(op, opts) do
      {:ok, _resp} ->
        {:ok, Path.join(cfg.public_base, key)}

      {:error, reason} ->
        Logger.error("R2 への画像アップロードに失敗しました: #{inspect(reason)}")
        {:error, reason}
    end
  end

  ## ローカル保存（フォールバック）

  defp store_local(content, ext) do
    dir = local_dir()
    File.mkdir_p!(dir)

    name = random_filename(ext)
    File.write!(Path.join(dir, name), content)

    {:ok, "/uploads/#{name}"}
  end

  defp local_dir do
    Application.get_env(:homepage_phoenix, :upload_dir) ||
      System.get_env("UPLOAD_DIR") ||
      Application.app_dir(:homepage_phoenix, ["priv", "static", "uploads"])
  end

  ## 共通

  # 推測・衝突を防ぐためランダムなファイル名にする（拡張子は元ファイルから）
  defp random_filename(ext) do
    rand = Base.url_encode64(:crypto.strong_rand_bytes(9), padding: false)
    "#{System.system_time(:millisecond)}-#{rand}#{ext}"
  end

  defp content_type(".png"), do: "image/png"
  defp content_type(".jpg"), do: "image/jpeg"
  defp content_type(".jpeg"), do: "image/jpeg"
  defp content_type(".gif"), do: "image/gif"
  defp content_type(".webp"), do: "image/webp"
  defp content_type(_), do: "application/octet-stream"
end
