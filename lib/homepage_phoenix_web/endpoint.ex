defmodule HomepagePhoenixWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :homepage_phoenix

  # セッションは Cookie に保存され署名される。
  # つまり内容は読み取れるが改ざんはできない。
  # 暗号化も行いたい場合は :encryption_salt を設定する。
  @session_options [
    store: :cookie,
    key: "_homepage_phoenix_key",
    signing_salt: "IXyVwOvc",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  # "priv/static" ディレクトリの静的ファイルを "/" で配信する。
  #
  # コードリロードが無効な場合（例: 本番環境）、
  # `gzip` オプションが有効になり、`phx.digest` の実行で
  # 生成された圧縮済み静的ファイルを配信する。
  plug Plug.Static,
    at: "/",
    from: :homepage_phoenix,
    gzip: not code_reloading?,
    only: HomepagePhoenixWeb.static_paths()

  # コードリロードはエンドポイントの
  # :code_reloader 設定で明示的に有効化できる。
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug HomepagePhoenixWeb.Router
end
