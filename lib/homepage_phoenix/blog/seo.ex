defmodule HomepagePhoenix.Blog.Seo do
  @moduledoc """
  投稿・ページ用の SEO メタ導出。DBカラムは持たない。
  """

  alias HomepagePhoenixWeb.Endpoint

  @site_name "Johmaruのホームページ"
  @description_limit 150

  def site_name, do: @site_name

  @doc "タブ/OG用タイトル。shortcode `:name:` を除去し trim。空なら site_name。"
  def document_title(title) when is_binary(title) do
    title =
      title
      |> String.replace(~r/:[a-z0-9_+-]+:/i, "")
      |> String.replace(~r/\s+/, " ")
      |> String.trim()

    if title == "", do: @site_name, else: title
  end

  @doc "本文からプレーンテキスト抜粋（最大150文字、超過時は末尾に …）。空本文は \"\"。"
  def description_from_body(body_md) when is_binary(body_md) do
    body_md
    |> String.replace(~r/!\[[^\]]*\]\([^)]*\)/, " ")
    |> String.replace(~r/\[([^\]]*)\]\([^)]*\)/, "\\1")
    |> String.replace(~r/[`#*_>]/, " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
    |> truncate()
  end

  def description_from_body(_), do: ""

  @doc "Markdown 最初の画像 URL。`![...](url)` の url。無ければ nil。"
  def first_image_url(body_md) when is_binary(body_md) do
    case Regex.run(~r/!\[[^\]]*\]\(([^)]+)\)/, body_md) do
      [_, url] -> url
      nil -> nil
    end
  end

  def first_image_url(_), do: nil

  @doc "相対パスを Endpoint 絶対 URL に。既に http(s) ならそのまま。"
  def absolute_url(path_or_url) when is_binary(path_or_url) do
    if String.starts_with?(path_or_url, ["http://", "https://"]) do
      path_or_url
    else
      Endpoint.url() <> "/" <> String.trim_leading(path_or_url, "/")
    end
  end

  @doc "BlogPosting JSON-LD 用 map（Jason.encode! 前）。"
  def article_json_ld(post, canonical_url) when is_struct(post) do
    base = %{
      "@context" => "https://schema.org",
      "@type" => "BlogPosting",
      "headline" => document_title(post.title),
      "dateModified" => DateTime.to_iso8601(post.updated_at),
      "mainEntityOfPage" => %{"@type" => "WebPage", "@id" => canonical_url},
      "author" => %{"@type" => "Person", "name" => "Johmaru"},
      "description" => description_from_body(post.body_md)
    }

    base =
      if post.published_at do
        Map.put(base, "datePublished", DateTime.to_iso8601(post.published_at))
      else
        base
      end

    case first_image_url(post.body_md) do
      nil -> base
      url -> Map.put(base, "image", [absolute_url(url)])
    end
  end

  defp truncate(text) do
    if String.length(text) > @description_limit do
      String.slice(text, 0, @description_limit) <> "…"
    else
      text
    end
  end
end
