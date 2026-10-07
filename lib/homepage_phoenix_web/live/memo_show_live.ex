defmodule HomepagePhoenixWeb.MemoShowLive do
  use HomepagePhoenixWeb, :live_view

  alias HomepagePhoenix.Blog.Seo
  alias HomepagePhoenix.Memos

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <article class="mx-auto max-w-4xl px-4 py-12 sm:px-6 lg:px-8">
        <div class="rounded-2xl border border-base-300 bg-base-100/80 p-5 shadow-xl backdrop-blur-sm sm:p-8">
          <.link href={~p"/memos"} class="text-sm text-primary hover:underline">
            ← メモ一覧に戻る
          </.link>

          <header class="mt-6 border-b border-base-300 pb-4">
            <h1 class="text-3xl font-bold tracking-tight">{@memo.title}</h1>

            <div class="mt-3 flex flex-wrap items-center gap-3 text-sm text-base-content/60">
              <span class={[
                "rounded-md px-2 py-0.5 text-xs",
                @memo.visibility == "public" && "bg-success/20 text-success",
                @memo.visibility == "unlisted" && "bg-base-300 text-base-content/70"
              ]}>
                {visibility_label(@memo.visibility)}
              </span>
              <time datetime={format_date(@memo.updated_at)}>{format_date(@memo.updated_at)}</time>
              <span>{String.length(@memo.body)}文字</span>
            </div>
          </header>

          <pre
            id="memo-body"
            class="mt-6 max-h-[70vh] overflow-auto whitespace-pre-wrap break-words rounded-xl border border-base-300 bg-base-100/80 p-5 font-mono text-sm leading-7 shadow-sm sm:p-7"
          >{@memo.body}</pre>

          <div
            id="memo-copy-controls"
            phx-hook="CopyText"
            phx-update="ignore"
            data-copy-target="memo-body"
            class="mt-5 flex flex-wrap items-center gap-3"
          >
            <button
              id="copy-memo-button"
              type="button"
              class="focus-ring inline-flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-primary-content transition hover:bg-primary/90"
            >
              <.icon name="hero-clipboard-document-mini" class="size-5" /> 全文をコピー
            </button>
            <span
              id="copy-memo-status"
              data-copy-status
              aria-live="polite"
              aria-atomic="true"
              class="min-h-5 text-sm text-base-content/70"
            >
            </span>
          </div>
        </div>
      </article>
    </Layouts.app>
    """
  end

  @impl Phoenix.LiveView
  def mount(%{"share_id" => share_id}, _session, socket) do
    memo = Memos.get_memo_by_share_id!(share_id)
    canonical_url = Seo.absolute_url(~p"/memos/#{memo.share_id}")

    {:ok,
     socket
     |> assign(:memo, memo)
     |> assign(:page_title, Seo.document_title(memo.title))
     |> assign(:meta_description, Seo.description_from_body(memo.body))
     |> assign(:canonical_url, canonical_url)
     |> assign(:og_type, "article")
     |> assign(:og_image, nil)
     |> assign(:json_ld, nil)
     |> assign(:robots, if(memo.visibility == "unlisted", do: "noindex, nofollow", else: nil))}
  end

  defp format_date(dt) do
    dt
    |> DateTime.to_date()
    |> Date.to_iso8601()
  end

  defp visibility_label("public"), do: "公開"
  defp visibility_label("unlisted"), do: "URL限定公開"
end
