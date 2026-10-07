defmodule HomepagePhoenixWeb.PostShowLive do
  use HomepagePhoenixWeb, :live_view

  alias HomepagePhoenix.Blog
  alias HomepagePhoenix.Blog.Seo

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <article class="mx-auto max-w-3xl px-4 py-12 sm:px-6 lg:px-8">
        <.link navigate={~p"/posts"} class="text-sm text-primary hover:underline">
          ← 投稿一覧に戻る
        </.link>

        <header class="mt-6 border-b border-base-300 pb-4">
          <h1 class="text-3xl font-bold tracking-tight">
            {raw(HomepagePhoenix.Emojis.to_safe_html(@post.title))}
          </h1>

          <div class="mt-3 flex flex-wrap items-center gap-3 text-sm text-base-content/60">
            <time :if={@post.published_at}>
              {format_date(@post.published_at)}
            </time>

            <div :if={@post.tags != []} class="flex flex-wrap gap-1">
              <.link
                :for={tag <- @post.tags}
                navigate={~p"/posts/tag/#{tag.name}"}
                class="rounded-md bg-base-200 px-2 py-0.5 hover:bg-base-300"
              >
                {tag.name}
              </.link>
            </div>
          </div>
        </header>

        <div class="mt-8 grid gap-8 lg:grid-cols-[1fr_16rem]">
          <div id="post-body" class="prose prose-base max-w-none dark:prose-invert">
            {raw(@body_html)}
          </div>

          <aside :if={@toc != []} class="hidden lg:block">
            <nav class="sticky top-8 rounded-xl border border-base-300 bg-base-100 p-4">
              <h2 class="mb-3 text-sm font-semibold text-base-content">目次</h2>
              <ul class="space-y-1 text-sm">
                <li :for={entry <- @toc}>
                  <a
                    href={"##{entry.anchor}"}
                    class={[
                      "block text-base-content/70 hover:text-primary",
                      entry.level == 3 && "pl-4"
                    ]}
                  >
                    {entry.text}
                  </a>
                </li>
              </ul>
            </nav>
          </aside>
        </div>
      </article>
    </Layouts.app>
    """
  end

  @impl Phoenix.LiveView
  def mount(%{"slug" => slug}, _session, socket) do
    post = Blog.get_post_by_slug!(slug)
    body_html = HomepagePhoenix.Blog.Renderer.to_html(post.body_md)
    toc = HomepagePhoenix.Blog.Renderer.to_toc(post.body_md)

    title = Seo.document_title(post.title)
    desc = Seo.description_from_body(post.body_md)
    canonical = Seo.absolute_url(~p"/posts/#{post.slug}")

    og_image =
      case Seo.first_image_url(post.body_md) do
        nil -> nil
        url -> Seo.absolute_url(url)
      end

    json_ld =
      post
      |> Seo.article_json_ld(canonical)
      |> Jason.encode!()
      |> String.replace("</", "<\\/")

    {:ok,
     socket
     |> assign(:post, post)
     |> assign(:body_html, body_html)
     |> assign(:toc, toc)
     |> assign(:page_title, title)
     |> assign(:meta_description, desc)
     |> assign(:canonical_url, canonical)
     |> assign(:og_type, "article")
     |> assign(:og_image, og_image)
     |> assign(:json_ld, json_ld)}
  end

  defp format_date(dt) do
    dt
    |> DateTime.to_date()
    |> Date.to_iso8601()
  end
end
