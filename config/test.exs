import Config

# テスト時のみ、パスワードハッシュアルゴリズムの複雑さを下げる
config :bcrypt_elixir, :log_rounds, 1

config :homepage_phoenix, HomepagePhoenix.Repo,
  username: System.get_env("POSTGRES_USER") || "postgres",
  password: System.get_env("POSTGRES_PASSWORD") || "postgres",
  database: System.get_env("POSTGRES_DB_TEST") || "homepage_phoenix_test",
  hostname: System.get_env("POSTGRES_HOST") || "localhost",
  port: String.to_integer(System.get_env("POSTGRES_PORT") || "5432"),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# テスト時はサーバーを起動しない。必要な場合は
# 以下の server オプションで有効化できる。
config :homepage_phoenix, HomepagePhoenixWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: System.get_env("SECRET_KEY_BASE_TEST") || String.duplicate("t", 64),
  server: false

# テスト時はメールを送信しない
config :homepage_phoenix, HomepagePhoenix.Mailer, adapter: Swoosh.Adapters.Test

# テストのアップロードは一時ディレクトリに書く（priv/static/uploads を汚さない）
config :homepage_phoenix,
       :upload_dir,
       Path.join(System.tmp_dir!(), "homepage_phoenix_test_uploads")

# 本番アダプターでのみ必要なため、swoosh API クライアントを無効化
config :swoosh, :api_client, false

# テスト時は警告とエラーのみ出力
config :logger, level: :warning

# テストコンパイルを高速化するため、プラグをランタイムで初期化
config :phoenix, :plug_init_mode, :runtime

# 有用だが潜在的にコストの高いランタイムチェックを有効化
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
