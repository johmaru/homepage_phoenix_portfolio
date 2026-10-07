import Config

# config/runtime.exs はリリースを含むすべての環境で実行される。
# コンパイル後、システム起動前に実行されるため、本番設定や
# シークレットを環境変数等から読み込むのに使用される。
# コンパイル時の設定はここに定義しないこと（適用されないため）。
# 以下のブロックは本番固有のランタイム設定を含む。

# ## リリースの使用
#
# `mix release` を使用する場合、起動時に PHX_SERVER=true を渡して
# サーバーを明示的に有効化する必要がある:
#
#     PHX_SERVER=true bin/homepage_phoenix start
#
# または `mix phx.gen.release` で `bin/server` スクリプトを生成し、
# 上記の環境変数を自動設定することもできる。
if System.get_env("PHX_SERVER") do
  config :homepage_phoenix, HomepagePhoenixWeb.Endpoint, server: true
end

if config_env() == :prod do
  maybe_ipv6 =
    if System.get_env("ECTO_IPV6") in ~w(true 1) do
      [:inet6]
    else
      []
    end

  config :homepage_phoenix, HomepagePhoenix.Repo,
    url:
      System.get_env("DATABASE_URL") ||
        raise("""
        environment variable DATABASE_URL is missing.
        Example: ecto://postgres:postgres@db:5432/homepage_phoenix_prod
        """),
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6,
    ssl: true

  # secret key base は Cookie やその他シークレットの署名・暗号化に使用される。
  # config/dev.exs と config/test.exs ではデフォルト値が使用されるが、
  # 本番では異なる値を使用すべき。バージョン管理に含めたくない場合は
  # 環境変数を使用する。
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :homepage_phoenix, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :homepage_phoenix, HomepagePhoenixWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    check_origin: ["//#{host}"],
    http: [
      # Cloud Run は IPv4 の 0.0.0.0 でリッスンすることを要求する。
      ip: {0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # ## SSL サポート
  #
  # SSL を有効にするには、エンドポイント設定に `https` キーを
  # 追加する:
  #
  #     config :homepage_phoenix, HomepagePhoenixWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # `cipher_suite` を `:strong` に設定すると、最新かつより安全な
  # SSL 暗号のみをサポートする。つまり古いブラウザやクライアントは
  # サポートされない可能性がある。より広いサポートが必要な場合は
  # `:compatible` に設定できる。
  #
  # `:keyfile` と `:certfile` にはディスク上のキーと証明書への
  # 絶対パス、または priv 内の相対パス（例: "priv/ssl/server.key"）を指定する。
  # サポートされるすべての SSL 設定オプションについては
  # https://hexdocs.pm/plug/Plug.SSL.html#configure/1 を参照。
  #
  # また config/prod.exs で `force_ssl` を設定し、データが http で
  # 送信されず常に https にリダイレクトされることを推奨:
  #
  #     config :homepage_phoenix, HomepagePhoenixWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # `force_ssl` の全オプションは `Plug.SSL` を参照。

  # ## メーラー設定
  #
  # 本番環境では異なるアダプターを使用するようメーラーを設定する必要がある。
  # Mailgun の設定例:
  #
  #     config :homepage_phoenix, HomepagePhoenix.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # ほとんどの非 SMTP アダプターは API クライアントを必要とする。
  # Swoosh は Req, Hackney, Finch を標準サポートする。
  # この設定は通常 config/prod.exs でコンパイル時に行う:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Req
  #
  # 詳細は https://hexdocs.pm/swoosh/Swoosh.html#module-installation を参照。
end
