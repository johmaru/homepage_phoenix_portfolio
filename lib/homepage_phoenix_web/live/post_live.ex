defmodule HomepagePhoenixWeb.PostLive do
  use HomepagePhoenixWeb, :live_view

  alias HomepagePhoenix.Blog
  alias HomepagePhoenix.Blog.Seo
  alias HomepagePhoenixWeb.Components.PostCard

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="mx-auto max-w-4xl px-4 py-12 sm:px-6 lg:px-8">
        <h1 class="border-b border-base-300 pb-2 text-2xl font-bold">投稿一覧</h1>

        <div
          :if={@tag_filter}
          class="mt-4 inline-flex items-center gap-2 rounded-md bg-base-200 px-3 py-1 text-sm"
        >
          <span>タグ: {@tag_filter}</span>
          <.link patch={~p"/posts"} class="text-base-content/60 hover:text-base-content">
            <.icon name="hero-x-mark" class="h-4 w-4" />
          </.link>
        </div>

        <div id="posts" phx-update="stream" class="mt-6 grid gap-4">
          <div :for={{id, post} <- @streams.posts} id={id}>
            <PostCard.post_card post={post} />
          </div>
        </div>

        <div :if={@total_pages > 1} class="mt-8 flex items-center justify-between">
          <.link
            :if={@page > 1}
            patch={page_path(@page - 1, @tag_filter)}
            class="rounded-lg border border-base-300 px-4 py-2 text-sm hover:bg-base-200"
          >
            前へ
          </.link>

          <span class="text-sm text-base-content/60">
            {@page} / {@total_pages}
          </span>

          <.link
            :if={@page < @total_pages}
            patch={page_path(@page + 1, @tag_filter)}
            class="rounded-lg border border-base-300 px-4 py-2 text-sm hover:bg-base-200"
          >
            次へ
          </.link>
        </div>
      </section>
    </Layouts.app>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    tag_filter = params["tag"]
    page = params["page"] || "1"

    result =
      if tag_filter do
        Blog.list_posts_by_tag(tag_filter, page: page)
      else
        Blog.list_posts(page: page)
      end

    {page_title, meta_description, canonical_path} = seo_meta(tag_filter, result.page)

    {:noreply,
     socket
     |> assign(:tag_filter, tag_filter)
     |> assign(:page, result.page)
     |> assign(:total_pages, result.total_pages)
     |> assign(:page_title, page_title)
     |> assign(:meta_description, meta_description)
     |> assign(:canonical_url, Seo.absolute_url(canonical_path))
     |> assign(:og_type, "website")
     |> assign(:og_image, nil)
     |> assign(:json_ld, nil)
     |> stream(:posts, result.posts, reset: true)}
  end

  # 一覧ページの SEO メタ。page > 1 なら canonical に page クエリを付ける。
  defp seo_meta(nil, 1), do: {"投稿一覧", "Johmaruのホームページのブログ投稿一覧", "/posts"}

  defp seo_meta(nil, page),
    do: {"投稿一覧", "Johmaruのホームページのブログ投稿一覧", "/posts?page=#{page}"}

  defp seo_meta(tag, 1), do: {"タグ: #{tag}", "タグ「#{tag}」の投稿一覧", "/posts/tag/#{tag}"}

  defp seo_meta(tag, page),
    do: {"タグ: #{tag}", "タグ「#{tag}」の投稿一覧", "/posts/tag/#{tag}?page=#{page}"}

  defp page_path(page, nil), do: ~p"/posts?page=#{page}"
  defp page_path(page, tag), do: ~p"/posts/tag/#{tag}?page=#{page}"
end
