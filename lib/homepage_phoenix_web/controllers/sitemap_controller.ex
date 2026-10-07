defmodule HomepagePhoenixWeb.SitemapController do
  @moduledoc """
  sitemap.xml を配信する。公開投稿と静的ページの URL を列挙する。
  """

  use HomepagePhoenixWeb, :controller

  alias HomepagePhoenix.Blog
  alias HomepagePhoenix.Blog.Seo
  alias HomepagePhoenix.Memos

  @static_paths ["/", "/profile", "/oshi", "/posts", "/activity", "/memos"]

  def index(conn, _params) do
    posts = Blog.list_published_for_sitemap()
    memos = Memos.list_public_memos_for_sitemap()

    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(200, build_xml(posts, memos))
  end

  defp build_xml(posts, memos) do
    static_urls = Enum.map(@static_paths, &url_element(&1, nil))

    post_urls =
      Enum.map(posts, fn %{slug: slug, updated_at: updated_at} ->
        lastmod = updated_at |> DateTime.to_date() |> Date.to_iso8601()
        url_element("/posts/#{slug}", lastmod)
      end)

    memo_urls =
      Enum.map(memos, fn %{share_id: share_id, updated_at: updated_at} ->
        lastmod = updated_at |> DateTime.to_date() |> Date.to_iso8601()
        url_element("/memos/#{share_id}", lastmod)
      end)

    [
      ~s(<?xml version="1.0" encoding="UTF-8"?>\n),
      ~s(<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n),
      static_urls,
      post_urls,
      memo_urls,
      "</urlset>"
    ]
  end

  defp url_element(path, nil) do
    ["  <url><loc>", xml_escape(Seo.absolute_url(path)), "</loc></url>\n"]
  end

  defp url_element(path, lastmod) do
    [
      "  <url><loc>",
      xml_escape(Seo.absolute_url(path)),
      "</loc><lastmod>",
      lastmod,
      "</lastmod></url>\n"
    ]
  end

  defp xml_escape(str) do
    str
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end
end
