defmodule HomepagePhoenixWeb.Router do
  use HomepagePhoenixWeb, :router

  import HomepagePhoenixWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HomepagePhoenixWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HomepagePhoenixWeb do
    pipe_through :browser

    get "/test", PageController, :test
    get "/sitemap.xml", SitemapController, :index

    live_session :current_scope,
      on_mount: [{HomepagePhoenixWeb.UserAuth, :mount_current_scope}] do
      live "/", HomeLive
      live "/profile", ProfileLive
      live "/oshi", OshiLive
      live "/posts", PostLive
      live "/posts/:slug", PostShowLive
      live "/posts/tag/:tag", PostLive, :by_tag
      live "/activity", ActivityLive
      live "/memos", MemoLive
      live "/memos/:share_id", MemoShowLive
    end
  end

  # 別のスコープではカスタムパイプラインを使用できる。
  # scope "/api", HomepagePhoenixWeb do
  #   pipe_through :api
  # end

  # 開発環境で LiveDashboard と Swoosh メールボックスプレビューを有効化
  if Application.compile_env(:homepage_phoenix, :dev_routes) do
    # 本番環境で LiveDashboard を使用する場合は、認証を必須とし、
    # 管理者のみアクセス可能にするべき。
    # アプリケーションに管理者専用セクションがない場合は、
    # Plug.BasicAuth で基本認証を設定できる
    # （SSL と併用することが前提）。
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: HomepagePhoenixWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## 認証ルート

  # すべての認証 live_session ブロックは pipe_through :browser のスコープ内にある。
  # これにより fetch_session, fetch_live_flash, put_root_layout,
  # fetch_current_scope_for_user プラグがすべての認証ルートで実行される。
  scope "/" do
    pipe_through :browser

    # 未認証ユーザー向けルート（登録、ログイン）。
    # POST /users/register と POST /users/log-in はコントローラールートのまま
    # （UserAuth.log_in_user/3 がセッション Cookie 書き込みに %Plug.Conn{} を必要とするため）。
    live_session :redirect_if_user_is_authenticated,
      on_mount: [
        {HomepagePhoenixWeb.UserAuth, :mount_current_scope},
        {HomepagePhoenixWeb.UserAuth, :redirect_if_user_is_authenticated}
      ] do
      live "/users/register", HomepagePhoenixWeb.UserRegistrationLive, :new
      live "/users/log-in", HomepagePhoenixWeb.UserSessionLive, :new
    end

    # マジックリンク確認ページ（認証の有無にかかわらずアクセス可能）。
    live_session :current_scope_auth,
      on_mount: [{HomepagePhoenixWeb.UserAuth, :mount_current_scope}] do
      live "/users/log-in/:token", HomepagePhoenixWeb.UserLoginConfirmationLive, :confirm
    end

    # ログイン / ログアウトの POST/DELETE（コントローラー: セッションに %Plug.Conn{} が必要）。
    post "/users/log-in", HomepagePhoenixWeb.UserSessionController, :create
    delete "/users/log-out", HomepagePhoenixWeb.UserSessionController, :delete

    # 認証済みユーザー向けルート（設定）。
    # PUT /users/settings はコントローラールートのまま（%Plug.Conn{} が必要）。
    # 設定ページは認証済みユーザーならアクセス可能。
    live_session :require_authenticated_user,
      on_mount: [
        {HomepagePhoenixWeb.UserAuth, :mount_current_scope},
        {HomepagePhoenixWeb.UserAuth, :require_authenticated_user}
      ] do
      live "/users/settings", HomepagePhoenixWeb.UserSettingsLive, :edit
    end

    # メール確認リンクは認証を必要とする
    live_session :confirm_email,
      on_mount: [
        {HomepagePhoenixWeb.UserAuth, :mount_current_scope},
        {HomepagePhoenixWeb.UserAuth, :require_authenticated_user}
      ] do
      live "/users/settings/confirm-email/:token",
           HomepagePhoenixWeb.UserSettingsLive,
           :confirm_email
    end
  end

  # PUT /users/settings は認証必須（コントローラー: セッションに %Plug.Conn{} が必要）。
  scope "/", HomepagePhoenixWeb do
    pipe_through [:browser, :require_authenticated_user]

    put "/users/settings", UserSettingsController, :update
  end

  scope "/", HomepagePhoenixWeb do
    pipe_through :browser

    live_session :require_admin,
      on_mount: [
        {HomepagePhoenixWeb.UserAuth, :mount_current_scope},
        {HomepagePhoenixWeb.UserAuth, :require_authenticated_user},
        {HomepagePhoenixWeb.AdminAuth, :require_admin}
      ] do
      live "/admin/posts", Admin.PostIndexLive
      live "/admin/posts/new", Admin.PostFormLive, :new
      live "/admin/posts/:slug/edit", Admin.PostFormLive, :edit
      live "/admin/activity", Admin.ActivityIndexLive
      live "/admin/activity/new", Admin.ActivityFormLive, :new
      live "/admin/activity/:id/edit", Admin.ActivityFormLive, :edit
      live "/admin/memos", Admin.MemoIndexLive
      live "/admin/memos/new", Admin.MemoFormLive, :new
      live "/admin/memos/:id/edit", Admin.MemoFormLive, :edit
      live "/admin/emojis", Admin.EmojiIndexLive
    end
  end
end
