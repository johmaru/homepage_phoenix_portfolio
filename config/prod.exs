import Config

# 静的ファイルのダイジェスト版を含むキャッシュマニフェストへの
# パスも含める点に注意。このマニフェストは `mix assets.deploy`
# タスクで生成され、静的ファイルのビルド後、本番サーバー起動前に
# 実行する必要がある。
config :homepage_phoenix, HomepagePhoenixWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json"

# Swoosh API クライアント設定
config :swoosh, api_client: Swoosh.ApiClient.Req

# Swoosh ローカルメモリストレージを無効化
config :swoosh, local: false

# 本番環境ではデバッグメッセージを出力しない
config :logger, level: :info

# 環境変数の読み込みを含む本番環境のランタイム設定は
# config/runtime.exs で行う。
