defmodule HomepagePhoenixWeb.Components.PostCard do
  @moduledoc """
  投稿カード function component。
  """

  use HomepagePhoenixWeb, :html

  alias HomepagePhoenix.Blog.Seo

  attr :post, HomepagePhoenix.Blog.Post, required: true

  def post_card(assigns) do
    ~H"""
    <article id={"post-card-#{@post.id}"} class="post-card group">
      <.link navigate={~p"/posts/#{@post.slug}"} class="post-card-link focus-ring">
        <div class="post-card-topline" aria-hidden="true"></div>
        <div class="flex items-start justify-between gap-4">
          <div>
            <p class="post-card-kicker">JOURNAL</p>
            <h3>{raw(HomepagePhoenix.Emojis.to_safe_html(@post.title))}</h3>
          </div>
          <.icon name="hero-arrow-up-right-mini" class="post-card-arrow size-5" />
        </div>
        <p class="post-card-excerpt">
          {raw(HomepagePhoenix.Emojis.to_safe_html(Seo.description_from_body(@post.body_md)))}
        </p>
        <div class="post-card-meta">
          <time :if={@post.published_at}>{format_date(@post.published_at)}</time>
          <div :if={@post.tags != []} class="post-card-tags">
            <span :for={tag <- @post.tags}>{tag.name}</span>
          </div>
        </div>
      </.link>
    </article>
    """
  end

  defp format_date(dt) do
    dt
    |> DateTime.to_date()
    |> Date.to_iso8601()
  end
end
