defmodule HomepagePhoenixWeb.Components.EmojiPicker do
  @moduledoc """
  カスタム絵文字ピッカー。ボタンクリックで対象フィールドへ `:name:` を挿入する。

  挿入は `insert_emoji` イベントを LiveView が受け、`InsertAtCursor` フックの
  `insert_at_cursor` イベント経由でフォーム入力に反映する。
  """

  use HomepagePhoenixWeb, :html

  attr :emojis, :list, required: true
  attr :field, :string, required: true

  def emoji_picker(assigns) do
    ~H"""
    <div class="mt-2 rounded-lg border border-base-300 bg-base-100 p-3">
      <p class="mb-2 text-xs font-medium text-base-content/60">絵文字（クリックで挿入）</p>

      <%= if @emojis == [] do %>
        <p class="text-xs text-base-content/60">
          絵文字がありません。
          <.link navigate={~p"/admin/emojis"} class="text-primary hover:underline">
            絵文字管理
          </.link>
          で追加できます
        </p>
      <% else %>
        <div class="flex flex-wrap gap-2">
          <button
            :for={emoji <- @emojis}
            type="button"
            phx-click="insert_emoji"
            phx-value-name={emoji.name}
            phx-value-field={@field}
            title={":#{emoji.name}:"}
            class="flex flex-col items-center gap-1 rounded-md border border-base-300 px-2 py-1.5 hover:bg-base-200"
          >
            <img class="custom-emoji" src={emoji.image_url} alt={":#{emoji.name}:"} />
            <span class="font-mono text-[10px] leading-none text-base-content/70">
              :{emoji.name}:
            </span>
          </button>
        </div>
      <% end %>
    </div>
    """
  end
end
