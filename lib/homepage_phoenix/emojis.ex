defmodule HomepagePhoenix.Emojis do
  @moduledoc """
  カスタム絵文字のコンテキスト。

  `:name:` ショートコードを画像表示へ展開するレンダリング契約も持つ。
  削除済み絵文字のショートコードはリテラル `:name:` のまま残る
  （投稿の一括書き換えはしない）。
  """

  import Ecto.Query, warn: false
  alias HomepagePhoenix.Repo

  alias HomepagePhoenix.Accounts.Scope
  alias HomepagePhoenix.Emojis.CustomEmoji

  @doc """
  全絵文字を name 昇順で取得する。
  """
  def list_emojis do
    from(e in CustomEmoji, order_by: [asc: :name])
    |> Repo.all()
  end

  @doc """
  表示時の置換用マップ `%{"name" => "image_url"}` を返す。
  """
  def shortcode_map do
    from(e in CustomEmoji, select: {e.name, e.image_url})
    |> Repo.all()
    |> Map.new()
  end

  @doc """
  絵文字を作成する。`user_id` は `current_scope.user` から設定する。
  attrs に `user_id` が含まれていても無視する。
  """
  def create_emoji(%Scope{user: user}, attrs) do
    %CustomEmoji{}
    |> CustomEmoji.changeset(Map.drop(attrs, ["user_id"]))
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  @doc """
  絵文字を削除する。画像ファイルは消さない（Blog.ImageStorage に削除 API が無いのと同じ）。
  """
  def delete_emoji(%CustomEmoji{} = emoji) do
    Repo.delete(emoji)
  end

  @doc """
  絵文字の changeset を生成する（フォーム用）。
  """
  def change_emoji(%CustomEmoji{} = emoji, attrs \\ %{}) do
    CustomEmoji.changeset(emoji, attrs)
  end

  @doc """
  プレーンテキスト（タイトル・活動本文）を安全な HTML に変換し、
  ショートコードを画像に展開する。

  `nil` / 非バイナリは空文字を返す。結果は `raw/1` で出力する前提。
  """
  def to_safe_html(nil), do: ""
  def to_safe_html(text) when not is_binary(text), do: ""

  def to_safe_html(text) when is_binary(text) do
    text
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
    |> expand_shortcodes()
  end

  @doc """
  既に HTML 化された文字列（ブログ本文）のショートコードを画像に展開する。

  未登録の名前はマッチ文字列 `:name:` をそのまま残す。
  `src` には DB の `image_url` を HTML エスケープして埋め込む。
  """
  def expand_shortcodes(html) when is_binary(html) do
    map = shortcode_map()

    if map == %{} do
      html
    else
      Regex.replace(~r/:([a-z0-9_]+):/, html, fn full, name ->
        case Map.fetch(map, name) do
          {:ok, url} ->
            url = url |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

            ~s(<img class="custom-emoji" src="#{url}" alt=":#{name}:" title=":#{name}:" loading="lazy" width="24" height="24">)

          :error ->
            full
        end
      end)
    end
  end
end
