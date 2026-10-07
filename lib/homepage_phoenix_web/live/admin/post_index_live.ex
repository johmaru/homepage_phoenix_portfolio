defmodule HomepagePhoenixWeb.Admin.PostIndexLive do
  use HomepagePhoenixWeb, :live_view

  alias HomepagePhoenix.Blog

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="mx-auto max-w-5xl px-4 py-12 sm:px-6 lg:px-8">
        <div class="flex items-center justify-between">
          <h1 class="text-2xl font-bold">投稿管理</h1>
          <.link
            navigate={~p"/admin/posts/new"}
            class="rounded-lg bg-primary px-4 py-2 text-sm font-medium text-primary-content hover:bg-primary/90"
          >
            新規投稿
          </.link>
        </div>

        <div class="mt-6 overflow-hidden rounded-xl border border-base-300">
          <table class="w-full text-sm">
            <thead class="bg-base-200 text-base-content/70">
              <tr>
                <th class="px-4 py-3 text-left">タイトル</th>
                <th class="px-4 py-3 text-left">slug</th>
                <th class="px-4 py-3 text-left">状態</th>
                <th class="px-4 py-3 text-left">公開日</th>
                <th class="px-4 py-3 text-right">操作</th>
              </tr>
            </thead>
            <tbody id="admin-posts" phx-update="stream">
              <tr :for={{id, post} <- @streams.posts} id={id} class="border-t border-base-300">
                <td class="px-4 py-3">
                  <.link navigate={~p"/admin/posts/#{post.slug}/edit"} class="hover:text-primary">
                    {post.title}
                  </.link>
                </td>
                <td class="px-4 py-3 text-base-content/70">{post.slug}</td>
                <td class="px-4 py-3">
                  <span class={[
                    "rounded-md px-2 py-0.5 text-xs",
                    post.status == "published" && "bg-success/20 text-success",
                    post.status == "draft" && "bg-base-300 text-base-content/70"
                  ]}>
                    {post.status}
                  </span>
                </td>
                <td class="px-4 py-3 text-base-content/70">
                  {post.published_at && format_date(post.published_at)}
                </td>
                <td class="px-4 py-3 text-right">
                  <button
                    phx-click="delete"
                    phx-value-slug={post.slug}
                    data-confirm="削除しますか？"
                    class="text-error hover:underline"
                  >
                    削除
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </Layouts.app>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    posts = Blog.list_admin_posts()
    {:ok, stream(socket, :posts, posts)}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"slug" => slug}, socket) do
    post = Blog.get_admin_post_by_slug!(slug)
    {:ok, _} = Blog.delete_post(post)

    posts = Blog.list_admin_posts()
    {:noreply, stream(socket, :posts, posts, reset: true)}
  end

  defp format_date(dt) do
    dt
    |> DateTime.to_date()
    |> Date.to_iso8601()
  end
end
