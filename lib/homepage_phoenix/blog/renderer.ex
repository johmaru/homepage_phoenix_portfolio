defmodule HomepagePhoenix.Blog.Renderer do
  @moduledoc """
  Markdown → HTML 変換と TOC 抽出。
  """

  @doc "Markdown を HTML に変換する。H2/H3 には anchor 用の id を付与する"
  def to_html(body_md) when is_binary(body_md) do
    body_md
    |> MDEx.to_html()
    |> unwrap_html()
    |> add_heading_ids()
    |> HomepagePhoenix.Emojis.expand_shortcodes()
  end

  # MDEx.to_html/1 は {:ok, html} を返す（バイナリを返す旧APIも許容）
  defp unwrap_html({:ok, html}), do: html
  defp unwrap_html(html) when is_binary(html), do: html

  @doc """
  H2 / H3 を抽出して TOC を返す。

  `anchor` は `to_html/1` が生成する `<h2 id="...">` / `<h3 id="...">`
  から直接抽出する。MDEx の id 生成ロジック（CJK 含む）を再現するのは
  不可能なため、HTML をパースして実 id を使う。
  """
  @spec to_toc(binary()) :: [%{level: 2 | 3, text: String.t(), anchor: String.t()}]
  def to_toc(body_md) when is_binary(body_md) do
    html = to_html(body_md)

    Regex.compile!(~S|<h([23])\s+id="([^"]+)"[^>]*>(.*?)</h\1>|, "s")
    |> Regex.scan(html, capture: :all)
    |> Enum.map(fn [_, level, anchor, inner] ->
      %{
        level: String.to_integer(level),
        text: strip_tags(inner) |> String.trim(),
        anchor: anchor
      }
    end)
  end

  defp strip_tags(html) do
    String.replace(html, ~r/<[^>]+>/, "")
  end

  # MDEx は見出しに id を付けないため、H2/H3 を走査して
  # 見出しテキストから anchor を生成し id 属性として注入する。
  # 重複時は -1, -2 ... のサフィックスを付ける。
  @heading_regex ~r/<h([23])>(.*?)<\/h\1>/s

  defp add_heading_ids(html) do
    @heading_regex
    |> Regex.scan(html)
    |> Enum.reduce({html, %{}}, fn [full, _level, inner], {html, counts} ->
      base = inner |> strip_tags() |> String.trim() |> slugify_anchor()
      n = Map.get(counts, base, 0)
      anchor = if n == 0, do: base, else: "#{base}-#{n}"
      counts = Map.put(counts, base, n + 1)

      tag = String.slice(full, 1, 2)
      replacement = "<#{tag} id=\"#{anchor}\">#{inner}</#{tag}>"
      {String.replace(html, full, replacement, global: false), counts}
    end)
    |> elem(0)
  end

  # CJK を含む Unicode 文字・数字を維持し、空白をハイフンに変換する。
  defp slugify_anchor(text) do
    text
    |> String.downcase()
    |> String.replace(~r/[^\p{L}\p{N}\s-]/u, "")
    |> String.replace(~r/[\s-]+/u, "-")
    |> String.trim("-")
  end
end
