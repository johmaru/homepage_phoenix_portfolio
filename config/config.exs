# このファイルは Config モジュールを使用してアプリケーションと
# その依存関係の設定を行う。
#
# この設定ファイルは依存関係より前に読み込まれ、
# このプロジェクトに限定される。

# 一般アプリケーション設定

import Config

config :homepage_phoenix, :scopes,
  user: [
    default: true,
    module: HomepagePhoenix.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: HomepagePhoenix.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :homepage_phoenix,
  generators: [timestamp_type: :utc_datetime]

config :homepage_phoenix, ecto_repos: [HomepagePhoenix.Repo]

# エンドポイント設定
config :homepage_phoenix, HomepagePhoenixWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: HomepagePhoenixWeb.ErrorHTML, json: HomepagePhoenixWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: HomepagePhoenix.PubSub,
  live_view: [signing_salt: "rNOj0yQY"]

# メーラー設定
#
# デフォルトでは "Local" アダプターを使用し、メールをローカルに保存する。
# ブラウザで "/dev/mailbox" からメールを確認できる。
#
# 本番環境では別のアダプターを `config/runtime.exs` で
# 設定することが推奨される。
config :homepage_phoenix, HomepagePhoenix.Mailer, adapter: Swoosh.Adapters.Local

# esbuild 設定（バージョン指定必須）
config :esbuild,
  version: "0.25.4",
  homepage_phoenix: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# tailwind 設定（バージョン指定必須）
config :tailwind,
  version: "4.1.7",
  homepage_phoenix: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Elixir の Logger 設定
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Phoenix で JSON パースに Jason を使用
config :phoenix, :json_library, Jason

# ExAws（R2 等の S3 互換ストレージアクセス）。HTTP クライアントは Req を使用
config :ex_aws,
  json_codec: Jason,
  http_client: ExAws.Request.Req

# 環境固有の設定をインポート。これは上書きされるように
# ファイルの末尾に置く必要がある。
import_config "#{config_env()}.exs"
