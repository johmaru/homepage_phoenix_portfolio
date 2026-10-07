defmodule HomepagePhoenixWeb.Admin.PostFormLive do
  use HomepagePhoenixWeb, :live_view

  alias HomepagePhoenix.Blog
  alias HomepagePhoenix.Blog.Post
  alias HomepagePhoenixWeb.Components.EmojiPicker

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="mx-auto max-w-4xl px-4 py-12 sm:px-6 lg:px-8">
        <h1 class="text-2xl font-bold">{@page_title}</h1>

        <div id="post-form-emoji-hook" phx-hook="InsertAtCursor">
          <.form
            for={@form}
            id="post-form"
            phx-change="validate"
            phx-submit="save_draft"
            class="mt-6 space-y-4"
          >
            <div>
              <.input
                field={@form[:title]}
                type="text"
                label="タイトル"
                placeholder="投稿タイトル"
              />
              <EmojiPicker.emoji_picker emojis={@emojis} field="title" />
            </div>

            <div class="grid gap-4 sm:grid-cols-2">
              <.input
                field={@form[:slug]}
                type="text"
                label="slug"
                placeholder="my-first-post"
              />

              <div>
                <label class="mb-1 block text-sm font-medium text-base-content">タグ（カンマ区切り）</label>
                <.input
                  field={@form[:tags]}
                  type="text"
                  value={@tags_input}
                  placeholder="elixir, phoenix"
                  phx-blur="update_tags"
                />
              </div>
            </div>

            <div>
              <label class="mb-1 block text-sm font-medium text-base-content">本文（Markdown）</label>
              <.input
                field={@form[:body_md]}
                type="textarea"
                rows="18"
                placeholder="# 見出し\n本文を Markdown で書く"
              />
              <EmojiPicker.emoji_picker emojis={@emojis} field="body_md" />
            </div>

            <div class="rounded-xl border border-base-300 p-4">
              <label class="mb-2 block text-sm font-medium text-base-content">
                画像アップロード（png / jpg / gif / webp、5MBまで）
              </label>

              <.live_file_input upload={@uploads.image} class="text-sm" />

              <div :for={entry <- @uploads.image.entries} class="mt-2 flex items-center gap-3 text-sm">
                <span class="truncate text-base-content/70">{entry.client_name}</span>
                <progress
                  max="100"
                  value={entry.progress}
                  class="h-2 w-40 appearance-none rounded bg-base-300 [&::-webkit-progress-value]:rounded [&::-webkit-progress-value]:bg-primary"
                >
                </progress>
                <span>{entry.progress}%</span>
                <button
                  type="button"
                  phx-click="cancel-upload"
                  phx-value-ref={entry.ref}
                  class="text-error hover:underline"
                >
                  キャンセル
                </button>
              </div>

              <p :for={err <- upload_errors(@uploads.image)} class="mt-2 text-sm text-error">
                {upload_error_message(err)}
              </p>
              <p
                :for={
                  err <- Enum.flat_map(@uploads.image.entries, &upload_errors(@uploads.image, &1))
                }
                class="mt-2 text-sm text-error"
              >
                {upload_error_message(err)}
              </p>

              <div class="mt-3 flex items-center gap-3">
                <button
                  :if={uploads_done?(@uploads.image)}
                  type="button"
                  id="insert-image-btn"
                  phx-click="insert_image"
                  class="rounded-lg bg-primary px-4 py-2 text-sm font-medium text-primary-content hover:bg-primary/90"
                >
                  画像を本文に挿入
                </button>

                <code :if={@uploaded_url} class="text-sm text-base-content/70">{@uploaded_url}</code>
              </div>
            </div>

            <div class="flex flex-wrap items-center gap-3">
              <button
                type="submit"
                name="post[status]"
                value="draft"
                class="rounded-lg border border-base-300 px-4 py-2 text-sm hover:bg-base-200"
              >
                下書き保存
              </button>

              <button
                type="button"
                id="preview-btn"
                phx-click="preview"
                class="rounded-lg border border-base-300 px-4 py-2 text-sm hover:bg-base-200"
              >
                プレビュー
              </button>

              <button
                type="button"
                id="publish-btn"
                phx-click="publish"
                class="rounded-lg bg-primary px-4 py-2 text-sm font-medium text-primary-content hover:bg-primary/90"
              >
                公開
              </button>
            </div>
          </.form>
        </div>

        <div :if={@preview_html} class="mt-8">
          <h2 class="mb-3 border-b border-base-300 pb-2 text-lg font-semibold">プレビュー</h2>
          <div id="preview-area" class="prose prose-base max-w-none dark:prose-invert">
            {raw(@preview_html)}
          </div>
        </div>
      </section>
    </Layouts.app>
    """
  end

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:preview_html, nil)
     |> assign(:tags_input, "")
     |> assign(:uploaded_url, nil)
     |> assign(:emojis, HomepagePhoenix.Emojis.list_emojis())
     |> allow_upload(:image,
       accept: ~w(.png .jpg .jpeg .gif .webp),
       max_entries: 1,
       max_file_size: 5_000_000,
       auto_upload: true
     )
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    post = %Post{}
    changeset = Blog.change_post(post, %{})

    socket
    |> assign(:page_title, "新規投稿")
    |> assign(:post, post)
    |> assign_form(changeset)
  end

  defp apply_action(socket, :edit, %{"slug" => slug}) do
    post = Blog.get_admin_post_by_slug!(slug)
    tags_input = post.tags |> Enum.map(& &1.name) |> Enum.join(",")
    changeset = Blog.change_post(post, %{})

    socket
    |> assign(:page_title, "投稿編集")
    |> assign(:post, post)
    |> assign(:tags_input, tags_input)
    |> assign_form(changeset)
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"post" => post_params}, socket) do
    changeset =
      socket.assigns.post
      |> Blog.change_post(post_params)

    {:noreply,
     socket
     |> assign_form(changeset)
     |> assign(:tags_input, post_params["tags"] || socket.assigns.tags_input)}
  end

  def handle_event("update_tags", %{"post" => %{"tags" => tags}}, socket) do
    {:noreply, assign(socket, :tags_input, tags || "")}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  def handle_event("insert_image", _params, socket) do
    entries = socket.assigns.uploads.image.entries

    if entries == [] or not uploads_done?(socket.assigns.uploads.image) do
      {:noreply, put_flash(socket, :error, "アップロード完了を待ってから挿入してください")}
    else
      results = Enum.map(entries, &consume_image(socket, &1))

      case Enum.find(results, &match?({:error, _}, &1)) do
        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, "画像の保存に失敗しました。ファイルを選び直してください")}

        nil ->
          urls = Enum.map(results, fn {:ok, url} -> url end)

          # consume 後はエントリが消えるため、URL を本文に挿入してフォームを更新
          markdown = urls |> Enum.map(&"![](#{&1})") |> Enum.join("\n\n")

          changeset =
            socket.assigns.form.source
            |> Ecto.Changeset.put_change(:body_md, append_to_body(socket, markdown))

          {:noreply,
           socket
           |> assign(:form, to_form(changeset, as: :post))
           |> assign(:uploaded_url, List.first(urls))
           |> put_flash(:info, "画像を本文に挿入しました")}
      end
    end
  end

  def handle_event("preview", _params, socket) do
    body_md = Ecto.Changeset.get_field(socket.assigns.form.source, :body_md) || ""
    html = HomepagePhoenix.Blog.Renderer.to_html(body_md)

    {:noreply, assign(socket, :preview_html, html)}
  end

  def handle_event("insert_emoji", %{"name" => name, "field" => field}, socket) do
    # Phoenix の to_form(..., as: :post) が付けるデフォルト入力 id へ変換する
    dom_id =
      case field do
        "title" -> "post_title"
        "body_md" -> "post_body_md"
        other -> other
      end

    {:noreply, push_event(socket, "insert_at_cursor", %{id: dom_id, text: ":#{name}:"})}
  end

  def handle_event("publish", _params, socket) do
    post_params = form_params(socket)
    post_params = Map.put(post_params, "status", "published")
    post_params = put_published_at(post_params, socket.assigns.post)

    case upsert_post(socket, post_params) do
      {:ok, _post} ->
        {:noreply,
         socket
         |> put_flash(:info, "投稿を公開しました")
         |> push_navigate(to: ~p"/admin/posts")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("save_draft", %{"post" => post_params}, socket) do
    post_params = Map.put(post_params, "status", "draft")

    case upsert_post(socket, post_params) do
      {:ok, _post} ->
        {:noreply,
         socket
         |> put_flash(:info, "下書きを保存しました")
         |> push_navigate(to: ~p"/admin/posts")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp upsert_post(socket, post_params) do
    tags = parse_tags(socket.assigns.tags_input)
    params = Map.put(post_params, "tags", tags)

    if socket.assigns.post.id do
      Blog.update_post(socket.assigns.post, params)
    else
      Blog.create_post(socket.assigns.current_scope, params)
    end
  end

  defp form_params(socket) do
    socket.assigns.form.source
    |> Ecto.Changeset.apply_changes()
    |> Map.from_struct()
    |> Map.take([:title, :slug, :body_md, :status, :published_at])
    |> Enum.into(%{}, fn {k, v} -> {to_string(k), v} end)
  end

  defp put_published_at(params, %{published_at: nil}),
    do: Map.put(params, "published_at", DateTime.utc_now() |> DateTime.to_iso8601())

  defp put_published_at(params, %{published_at: _existing}), do: params

  defp parse_tags(""), do: []

  defp parse_tags(input) when is_binary(input) do
    input
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset, as: :post))
  end

  ## 画像アップロード

  # アップロード済みファイルを Blog.ImageStorage に保存し、配信 URL を返す。
  # R2 が設定されていれば R2、なければローカル（priv/static/uploads）。
  defp consume_image(socket, entry) do
    consume_uploaded_entry(socket, entry, fn meta ->
      ext = entry.client_name |> Path.extname() |> String.downcase()
      content = File.read!(meta.path)

      {:ok, Blog.ImageStorage.store(content, ext)}
    end)
  end

  defp append_to_body(socket, markdown) do
    body = Ecto.Changeset.get_field(socket.assigns.form.source, :body_md) || ""
    join_body(body, markdown)
  end

  defp join_body("", markdown), do: markdown

  defp join_body(body, markdown) do
    body = if String.ends_with?(body, "\n"), do: body, else: body <> "\n"
    body <> "\n" <> markdown
  end

  defp uploads_done?(%{entries: []}), do: false

  defp uploads_done?(%{entries: entries}), do: Enum.all?(entries, & &1.done?)

  defp upload_error_message(:too_large), do: "ファイルサイズが上限（5MB）を超えています"
  defp upload_error_message(:not_accepted), do: "対応していない形式です"
  defp upload_error_message(:too_many_files), do: "アップロードできるのは1ファイルまでです"
  defp upload_error_message(:external_client_failure), do: "アップロードに失敗しました"
  defp upload_error_message(other), do: "アップロードエラー: #{inspect(other)}"
end
