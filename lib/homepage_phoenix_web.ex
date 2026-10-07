defmodule HomepagePhoenixWeb do
  @moduledoc """
  ウェブインターフェース（コントローラー、コンポーネント、チャネルなど）を
  定義するエントリポイント。

  アプリケーションでは次のように使用する:

      use HomepagePhoenixWeb, :controller
      use HomepagePhoenixWeb, :html

  以下の定義はすべてのコントローラーやコンポーネント等で実行されるため、
  import、use、alias に絞って短くシンプルに保つこと。

  quote 内で関数を定義しないこと。代わりに別モジュールを定義し、
  ここで import すること。
  """

  def static_paths, do: ~w(assets fonts images uploads favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # パイプラインで使用する共通のコネクション・コントローラー関数を import
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, formats: [:html, :json]

      use Gettext, backend: HomepagePhoenixWeb.Gettext

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # コントローラーの便利関数を import
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # HTML レンダリング用の共通ヘルパーを組み込み
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # 翻訳
      use Gettext, backend: HomepagePhoenixWeb.Gettext

      # HTML エスケープ機能
      import Phoenix.HTML
      # コア UI コンポーネント
      import HomepagePhoenixWeb.CoreComponents

      # テンプレートで使用する共通モジュール
      alias Phoenix.LiveView.JS
      alias HomepagePhoenixWeb.Layouts

      # ~p シギルによるルート生成
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: HomepagePhoenixWeb.Endpoint,
        router: HomepagePhoenixWeb.Router,
        statics: HomepagePhoenixWeb.static_paths()
    end
  end

  @doc """
  use 時に、対応する controller/live_view 等へディスパッチする。
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
