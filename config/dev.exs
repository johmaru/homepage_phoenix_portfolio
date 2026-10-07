import Config

config :homepage_phoenix, HomepagePhoenix.Repo,
  username: System.get_env("POSTGRES_USER") || "postgres",
  password: System.get_env("POSTGRES_PASSWORD") || "postgres",
  database: System.get_env("POSTGRES_DB") || "homepage_phoenix_dev",
  hostname: System.get_env("POSTGRES_HOST") || "localhost",
  port: String.to_integer(System.get_env("POSTGRES_PORT") || "5432"),
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# 開発環境ではキャッシュを無効化し、デバッグと
# コードリロードを有効にする。
#
# watchers 設定は外部ウォッチャーを起動するのに使用できる。
# 例えば .js や .css ソースのバンドルに使用する。
config :homepage_phoenix, HomepagePhoenixWeb.Endpoint,
  # ループバック IPv4 アドレスにバインドすると他のマシンからのアクセスを防げる。
  # `ip: {0, 0, 0, 0}` に変更すれば他のマシンからのアクセスを許可できる。
  http: [ip: {0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT") || "4000")],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: System.get_env("SECRET_KEY_BASE_DEV") || String.duplicate("d", 64),
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:homepage_phoenix, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:homepage_phoenix, ~w(--watch)]}
  ]

# ## SSL サポート
#
# 開発環境で HTTPS を使用する場合、以下の Mix タスクで
# 自己署名証明書を生成できる:
#
#     mix phx.gen.cert
#
# 詳細は `mix help phx.gen.cert` を参照。
#
# 上記の `http:` 設定は以下に置き換え可能:
#
#     https: [
#       port: 4001,
#       cipher_suite: :strong,
#       keyfile: "priv/cert/selfsigned_key.pem",
#       certfile: "priv/cert/selfsigned.pem"
#     ],
#
# 必要に応じて `http:` と `https:` の両方を設定し、
# 異なるポートで http サーバーと https サーバーを両方起動できる。

# ブラウザリロードのために静的ファイルとテンプレートを監視。
config :homepage_phoenix, HomepagePhoenixWeb.Endpoint,
  live_reload: [
    web_console_logger: true,
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/homepage_phoenix_web/(?:controllers|live|components|router)/?.*\.(ex|heex)$"
    ]
  ]

# ダッシュボードとメールボックスの開発ルートを有効化
config :homepage_phoenix, dev_routes: true

# 開発ログにメタデータとタイムスタンプを含めない
config :logger, :default_formatter, format: "[$level] $message\n"

# 開発環境ではより深いスタックトレースを設定。本番環境で大きなスタックトレースの
# 構築はコストが高くなるため、この設定は避けること。
config :phoenix, :stacktrace_depth, 20

# 開発時のコンパイルを高速化するため、プラグをランタイムで初期化
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  # レンダリングされたマークアップにデバッグアノテーションと位置情報を含める。
  # この設定を変更するには mix clean とフル再コンパイルが必要。
  debug_heex_annotations: true,
  debug_attributes: true,
  # 有用だが潜在的にコストの高いランタイムチェックを有効化
  enable_expensive_runtime_checks: true

# 本番アダプターでのみ必要なため、swoosh API クライアントを無効化。
config :swoosh, :api_client, false
