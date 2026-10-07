defmodule HomepagePhoenixWeb.MemoLive do
  use HomepagePhoenixWeb, :live_view

  alias HomepagePhoenix.Blog
  alias HomepagePhoenix.Memos

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="mx-auto max-w-4xl px-4 py-12 sm:px-6 lg:px-8">
        <h1 class="border-b border-base-300 pb-2 text-2xl font-bold">メモ</h1>

        <div id="memos" phx-update="stream" class="mt-6 grid gap-4">
          <div :for={{id, memo} <- @streams.memos} id={id}>
            <article id={"memo-card-#{memo.id}"} class="post-card group">
              <.link href={~p"/memos/#{memo.share_id}"} class="post-card-link focus-ring">
                <div class="post-card-topline" aria-hidden="true"></div>
                <div class="flex items-start justify-between gap-4">
                  <div>
                    <p class="post-card-kicker">MEMO</p>
                    <h3>{memo.title}</h3>
                  </div>
                  <.icon name="hero-arrow-up-right-mini" class="post-card-arrow size-5" />
                </div>
                <p class="post-card-excerpt">{Blog.Seo.description_from_body(memo.body)}</p>
                <div class="post-card-meta">
                  <time datetime={format_date(memo.updated_at)}>{format_date(memo.updated_at)}</time>
                </div>
              </.link>
            </article>
          </div>
        </div>

        <div
          :if={@memos_empty?}
          id="memos-empty"
          class="mt-6 rounded-xl border border-base-300 p-8 text-center text-base-content/60"
        >
          公開中のメモはありません
        </div>
      </section>
    </Layouts.app>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    memos = Memos.list_public_memos()

    {:ok,
     socket
     |> assign(:memos_empty?, memos == [])
     |> assign(:page_title, "メモ")
     |> assign(:meta_description, "Johmaruが共有するテキストメモ一覧")
     |> assign(:canonical_url, Blog.Seo.absolute_url("/memos"))
     |> assign(:og_type, "website")
     |> assign(:og_image, nil)
     |> assign(:json_ld, nil)
     |> assign(:robots, nil)
     |> stream(:memos, memos)}
  end

  defp format_date(dt) do
    dt
    |> DateTime.to_date()
    |> Date.to_iso8601()
  end
end
