defmodule HomepagePhoenixWeb.HomeLive do
  use HomepagePhoenixWeb, :live_view

  alias HomepagePhoenixWeb.Components.PostCard

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section id="home-hero" class="home-hero relative isolate overflow-hidden">
        <div
          id="aurora-bg"
          class="aurora-bg"
          aria-hidden="true"
          phx-hook="AuroraCursor"
          phx-update="ignore"
        >
          <%!-- 既存の aurora-blob-1 から aurora-blob-10 をここに残す --%>
          <div class="aurora-blob aurora-blob-1"></div>

          <div class="aurora-blob aurora-blob-2"></div>

          <div class="aurora-blob aurora-blob-3"></div>

          <div class="aurora-blob aurora-blob-4"></div>

          <div class="aurora-blob aurora-blob-5"></div>

          <div class="aurora-blob aurora-blob-6"></div>

          <div class="aurora-blob aurora-blob-7"></div>

          <div class="aurora-blob aurora-blob-8"></div>

          <div class="aurora-blob aurora-blob-9"></div>

          <div class="aurora-blob aurora-blob-10"></div>

          <div class="aurora-particles"></div>

          <div class="aurora-cursor-glow" id="aurora-cursor-glow"></div>
        </div>

        <div class="home-hero-content relative z-10 mx-auto grid min-h-[42rem] max-w-6xl items-center gap-8 px-4 py-28 sm:px-6 lg:grid-cols-[minmax(0,1.35fr)_minmax(17rem,22rem)] lg:px-8">
          <div class="max-w-3xl">
            <h1
              id="typewriter"
              data-text="Johmaruのホームページにようこそ！"
              phx-hook="Typewriter"
              phx-update="ignore"
              class="home-hero-title"
            >
            </h1>
            <p class="home-hero-copy">好きなもの、学んでいる技術、日々の記録を集めた個人サイトです。</p>
            <div id="home-primary-actions" class="mt-8 flex flex-wrap gap-3">
              <.link navigate={~p"/profile"} class="home-button home-button-primary">
                プロフィールを見る <.icon name="hero-arrow-up-right-mini" class="size-4" />
              </.link>
              <.link navigate={~p"/posts"} class="home-button home-button-secondary">
                最新の投稿 <.icon name="hero-arrow-right-mini" class="size-4" />
              </.link>
            </div>
          </div>

          <aside
            id="home-recent-activity"
            class="home-activity-panel w-full max-w-md justify-self-stretch lg:mt-12 lg:justify-self-end"
            aria-label="最近の活動"
          >
            <div class="home-activity-panel-inner">
              <div class="flex items-baseline justify-between gap-3">
                <div>
                  <p class="home-eyebrow">RECENT ACTIVITY</p>
                  <h2 class="text-lg font-semibold">最近の活動</h2>
                </div>
                <.link
                  navigate={~p"/activity"}
                  class="text-xs text-base-content/70 hover:text-base-content"
                >
                  すべて
                </.link>
              </div>

              <div
                :if={@recent_entries == []}
                id="home-activity-empty"
                class="mt-4 text-sm text-base-content/70"
              >
                まだ活動・更新はありません
              </div>

              <ul :if={@recent_entries != []} id="home-activity-list" class="mt-4 space-y-3">
                <li :for={entry <- @recent_entries} class="home-activity-panel-item">
                  <div class="flex flex-wrap items-center gap-2 text-xs">
                    <time class="text-base-content/60">{format_date(entry.occurred_at)}</time>
                    <span class={[
                      "rounded-md px-2 py-0.5",
                      entry.kind == "activity" && "bg-primary/20 text-primary",
                      entry.kind == "update" && "bg-info/20 text-info"
                    ]}>
                      {kind_label(entry.kind)}
                    </span>
                  </div>
                  <p class="mt-1 truncate text-sm font-medium">
                    {raw(HomepagePhoenix.Emojis.to_safe_html(entry.title))}
                  </p>
                </li>
              </ul>
            </div>
          </aside>
        </div>
      </section>

      <section id="home-about" class="home-section mx-auto max-w-6xl px-4 py-20 sm:px-6 lg:px-8">
        <div class="home-section-heading">
          <p class="home-eyebrow">ABOUT THIS HOMEPAGE</p>
          <h2>コンテンツ</h2>
          <p>プロフィール、推し、開発や日々の記録をまとめています。</p>
        </div>
        <div id="home-interest-links" class="mt-10 grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          <.link
            :for={
              {title, copy, path, icon} <- [
                {"プロフィール", "Johmaruについて", ~p"/profile", "hero-user-mini"},
                {"推し", "好きな作品とキャラクター", ~p"/oshi", "hero-heart-mini"},
                {"投稿", "技術と日々の記録", ~p"/posts", "hero-pencil-square-mini"},
                {"活動", "最近の活動と更新履歴", ~p"/activity", "hero-clock-mini"}
              ]
            }
            navigate={path}
            class="home-interest-card group"
          >
            <.icon name={icon} class="size-5" />
            <h3>{title}</h3>
            <p>{copy}</p>
            <.icon name="hero-arrow-up-right-mini" class="home-card-arrow size-4" />
          </.link>
        </div>
      </section>

      <section
        id="home-recent-posts"
        class="home-section mx-auto max-w-6xl px-4 py-20 sm:px-6 lg:px-8"
      >
        <div class="home-section-heading">
          <p class="home-eyebrow">LATEST STORIES</p>
          <h2>最新の投稿</h2>
        </div>
        <div :if={@recent_posts == []} id="home-posts-empty" class="home-empty-state mt-8">
          まだ投稿はありません
        </div>
        <div :if={@recent_posts != []} class="mt-8 grid gap-4 lg:grid-cols-3">
          <PostCard.post_card :for={post <- @recent_posts} post={post} />
        </div>
        <.link navigate={~p"/posts"} class="home-button home-button-secondary mt-8">
          すべての投稿を見る <.icon name="hero-arrow-right-mini" class="size-4" />
        </.link>
      </section>
    </Layouts.app>
    """
  end

  defp format_date(dt) do
    dt
    |> DateTime.to_date()
    |> Date.to_iso8601()
  end

  defp kind_label("activity"), do: "活動"
  defp kind_label("update"), do: "更新"

  def mount(_params, _session, socket) do
    recent_posts = HomepagePhoenix.Blog.list_recent_posts(limit: 3)
    recent_entries = HomepagePhoenix.Activity.list_recent_entries(limit: 3)

    {:ok,
     socket
     |> assign(:recent_posts, recent_posts)
     |> assign(:recent_entries, recent_entries)
     |> assign(:meta_description, "Johmaruのホームページ")
     |> assign(:canonical_url, HomepagePhoenix.Blog.Seo.absolute_url("/"))
     |> assign(:og_type, "website")
     |> assign(:og_image, nil)
     |> assign(:json_ld, nil)}
  end
end
