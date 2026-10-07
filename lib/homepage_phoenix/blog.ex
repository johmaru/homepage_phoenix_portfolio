defmodule HomepagePhoenix.Blog do
  @moduledoc """
  Blog コンテキスト。

  公開側クエリは必ず `status == "published"` かつ `published_at <= now()` で絞り込む。
  """

  import Ecto.Query, warn: false
  alias HomepagePhoenix.Repo

  alias HomepagePhoenix.Accounts.Scope
  alias HomepagePhoenix.Blog.{Post, Tag, PostTag}

  @per_page 10

  ## 公開側

  @doc """
  公開済み投稿をページング付きで取得する。

  ## Examples

      iex> list_posts(page: 1)
      %{posts: [...], page: 1, total_pages: 3}

  """
  def list_posts(opts \\ []) do
    page = normalize_page(opts[:page])
    now = DateTime.utc_now()

    base =
      from(p in Post,
        where: p.status == "published" and p.published_at <= ^now,
        order_by: [desc: p.published_at, desc: p.id],
        preload: [:user, :tags]
      )

    total = Repo.aggregate(base, :count)

    total_pages = max(1, div(total + @per_page - 1, @per_page))
    page = min(page, total_pages)

    posts =
      base
      |> limit(^@per_page)
      |> offset(^((page - 1) * @per_page))
      |> join(:inner, [p], u in assoc(p, :user))
      |> join(:left, [p, u], t in assoc(p, :tags))
      |> preload([p, u, t], user: u, tags: t)

    %{posts: Repo.all(posts), page: page, total_pages: total_pages}
  end

  @doc """
  sitemap 用。公開済みかつ published_at <= now の全件。ページングなし。
  """
  def list_published_for_sitemap do
    now = DateTime.utc_now()

    from(p in Post,
      where: p.status == "published" and p.published_at <= ^now,
      order_by: [desc: p.published_at, desc: p.id],
      select: %{slug: p.slug, published_at: p.published_at, updated_at: p.updated_at}
    )
    |> Repo.all()
  end

  @doc """
  HomeLive 用に最新公開投稿を limit 件取得する。
  """
  def list_recent_posts(opts \\ []) do
    limit = opts[:limit] || 3
    now = DateTime.utc_now()

    from(p in Post,
      where: p.status == "published" and p.published_at <= ^now,
      order_by: [desc: p.published_at, desc: p.id],
      limit: ^limit,
      preload: [:user, :tags]
    )
    |> Repo.all()
  end

  @doc """
  公開済み投稿を slug で取得する。draft または未来予約投稿は 404。
  """
  def get_post_by_slug!(slug) do
    now = DateTime.utc_now()

    from(p in Post,
      where:
        p.slug == ^slug and p.status == "published" and
          (is_nil(p.published_at) or p.published_at <= ^now),
      preload: [:user, :tags]
    )
    |> Repo.one!()
  end

  @doc """
  タグ名で絞り込んだ公開投稿一覧。
  """
  def list_posts_by_tag(tag_name, opts \\ []) do
    page = normalize_page(opts[:page])
    now = DateTime.utc_now()

    base =
      from(p in Post,
        join: pt in PostTag,
        on: pt.post_id == p.id,
        join: t in Tag,
        on: t.id == pt.tag_id,
        where:
          t.name == ^tag_name and p.status == "published" and
            p.published_at <= ^now,
        order_by: [desc: p.published_at, desc: p.id],
        preload: [:user, :tags]
      )

    total = Repo.aggregate(base, :count)
    total_pages = max(1, div(total + @per_page - 1, @per_page))
    page = min(page, total_pages)

    posts =
      base
      |> limit(^@per_page)
      |> offset(^((page - 1) * @per_page))
      |> Repo.all()

    %{posts: posts, page: page, total_pages: total_pages}
  end

  ## 管理側

  @doc """
  管理画面用に draft 含む全件を取得する。
  """
  def list_admin_posts do
    from(p in Post,
      order_by: [desc: p.inserted_at],
      preload: [:user, :tags]
    )
    |> Repo.all()
  end

  @doc """
  管理画面用に slug で取得する。draft 含む。
  """
  def get_admin_post_by_slug!(slug) do
    from(p in Post,
      where: p.slug == ^slug,
      preload: [:user, :tags]
    )
    |> Repo.one!()
  end

  @doc """
  投稿を作成する。`user_id` は `current_scope.user` から設定する。
  attrs に `user_id` が含まれていても無視する。
  """
  def create_post(%Scope{user: user}, attrs) do
    tags = extract_tags(attrs)

    result =
      %Post{}
      |> Post.changeset(Map.drop(attrs, ["tags", "user_id"]))
      |> Ecto.Changeset.put_assoc(:user, user)
      |> Repo.insert()

    case result do
      {:ok, post} -> {:ok, associate_tags(post, tags)}
      error -> error
    end
  end

  @doc """
  投稿を更新する。
  """
  def update_post(%Post{} = post, attrs) do
    tags = extract_tags(attrs)

    result =
      post
      |> Post.changeset(Map.drop(attrs, ["tags", "user_id"]))
      |> Repo.update()

    case result do
      {:ok, post} -> {:ok, associate_tags(post, tags, replace: true)}
      error -> error
    end
  end

  @doc """
  投稿を公開状態にする。`status` を `published` にし、
  `published_at` が未設定なら現在時刻を設定する。
  """
  def publish_post(%Post{} = post) do
    now = DateTime.utc_now()

    post
    |> Post.changeset(%{"status" => "published", "published_at" => to_iso8601(now)})
    |> Repo.update()
  end

  @doc """
  投稿を削除する。
  """
  def delete_post(%Post{} = post) do
    Repo.delete(post)
  end

  @doc """
  投稿の changeset を生成する（フォーム用）。
  """
  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  ## タグ

  @doc """
  全タグを取得する。
  """
  def list_tags do
    Repo.all(from(t in Tag, order_by: t.name))
  end

  @doc """
  新しいタグを作成する。
  """
  def create_tag(attrs) do
    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  タグ名のリストから、存在しないものを作成して返す。
  """
  def ensure_tags(names) when is_list(names) do
    names =
      names
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.uniq()

    existing =
      from(t in Tag, where: t.name in ^names)
      |> Repo.all()

    existing_names = MapSet.new(existing, & &1.name)

    new_names = Enum.reject(names, &MapSet.member?(existing_names, &1))

    new_tags =
      Enum.map(new_names, fn name ->
        %Tag{}
        |> Tag.changeset(%{"name" => name})
        |> Repo.insert!()
      end)

    existing ++ new_tags
  end

  ## スラッグ生成

  @doc """
  タイトルから URL 用スラッグを生成する。
  ASCII 英数字・スペースのみ対応。日本語等の非 ASCII が混ざると空文字を返す。
  """
  def slugify(title) when is_binary(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/[\s-]+/, "-")
    |> String.trim("-")
  end

  ## 内部関数

  defp normalize_page(nil), do: 1
  defp normalize_page(page) when is_integer(page), do: max(page, 1)

  defp normalize_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {n, _} when n >= 1 -> n
      _ -> 1
    end
  end

  defp extract_tags(attrs) do
    case attrs["tags"] do
      nil -> []
      names when is_list(names) -> names
      names when is_binary(names) -> String.split(names, ",", trim: true)
      _ -> []
    end
  end

  # tags は has_many through の読み取り専用 assoc のため put_assoc できず、
  # 中間テーブルの PostTag を直接作成して紐付ける。
  defp associate_tags(post, names, opts \\ [])

  defp associate_tags(post, [], _opts), do: post

  defp associate_tags(post, names, opts) do
    if opts[:replace] do
      Repo.delete_all(from(pt in PostTag, where: pt.post_id == ^post.id))
    end

    tags = ensure_tags(names)

    Enum.each(tags, fn tag ->
      Repo.insert!(%PostTag{post_id: post.id, tag_id: tag.id},
        on_conflict: :nothing,
        conflict_target: [:post_id, :tag_id]
      )
    end)

    Repo.preload(post, :tags, force: true)
  end

  defp to_iso8601(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
end
