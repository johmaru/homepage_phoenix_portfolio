defmodule HomepagePhoenix.Application do
  # https://hexdocs.pm/elixir/Application.html を参照してください。
  # OTP アプリケーションの詳細は上記ドキュメントを参照。
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HomepagePhoenixWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:homepage_phoenix, :dns_cluster_query) || :ignore},
      HomepagePhoenix.Repo,
      {Phoenix.PubSub, name: HomepagePhoenix.PubSub},
      # リクエスト受付開始。通常は子要素の最後に配置する。
      HomepagePhoenixWeb.Endpoint
    ]

    # 他の戦略とサポートされるオプションについては
    # https://hexdocs.pm/elixir/Supervisor.html を参照。
    opts = [strategy: :one_for_one, name: HomepagePhoenix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # アプリケーションが更新されたらエンドポイント設定も
  # 更新するよう Phoenix に指示する。
  @impl true
  def config_change(changed, _new, removed) do
    HomepagePhoenixWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
