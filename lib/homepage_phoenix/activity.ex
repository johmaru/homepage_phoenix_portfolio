defmodule HomepagePhoenix.Activity do
  @moduledoc """
  活動・更新エントリのコンテキスト。

  公開側クエリは必ず `status == "published"` かつ `occurred_at <= now()` で絞り込む。
  """

  import Ecto.Query, warn: false
  alias HomepagePhoenix.Repo

  alias HomepagePhoenix.Accounts.Scope
  alias HomepagePhoenix.Activity.Entry

  @per_page 10

  @doc """
  公開済みエントリをページング付きで取得する。

  `opts[:kind]` が `"activity"` / `"update"` のときのみ種別で絞り込む
  （無効な値は無視される）。

  ## Examples

      iex> list_entries(page: 1)
      %{entries: [...], page: 1, total_pages: 1}

  """
  def list_entries(opts \\ []) do
    page = normalize_page(opts[:page])
    now = DateTime.utc_now()

    base =
      from(e in Entry,
        where: e.status == "published" and e.occurred_at <= ^now,
        order_by: [desc: e.occurred_at, desc: e.id]
      )

    base =
      case opts[:kind] do
        kind when kind in ["activity", "update"] -> where(base, [e], e.kind == ^kind)
        _ -> base
      end

    total = Repo.aggregate(base, :count)

    total_pages = max(1, div(total + @per_page - 1, @per_page))
    page = min(page, total_pages)

    entries =
      base
      |> limit(^@per_page)
      |> offset(^((page - 1) * @per_page))
      |> Repo.all()

    %{entries: entries, page: page, total_pages: total_pages}
  end

  @doc """
  HomeLive 用に最新公開エントリを limit 件取得する（デフォルト 5 件）。
  """
  def list_recent_entries(opts \\ []) do
    limit = opts[:limit] || 5
    now = DateTime.utc_now()

    from(e in Entry,
      where: e.status == "published" and e.occurred_at <= ^now,
      order_by: [desc: e.occurred_at, desc: e.id],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  管理画面用に draft 含む全件を取得する。
  """
  def list_admin_entries do
    from(e in Entry, order_by: [desc: e.inserted_at])
    |> Repo.all()
  end

  @doc """
  管理画面用に id で取得する。draft 含む。
  """
  def get_admin_entry!(id) do
    Repo.get!(Entry, id)
  end

  @doc """
  エントリを作成する。`user_id` は `current_scope.user` から設定する。
  attrs に `user_id` が含まれていても無視する。
  """
  def create_entry(%Scope{user: user}, attrs) do
    %Entry{}
    |> Entry.changeset(Map.drop(attrs, ["user_id"]))
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  @doc """
  エントリを更新する。
  """
  def update_entry(%Entry{} = entry, attrs) do
    entry
    |> Entry.changeset(Map.drop(attrs, ["user_id"]))
    |> Repo.update()
  end

  @doc """
  エントリを公開状態にする。`status` を `published` にし、
  `occurred_at` が未設定なら現在時刻を設定する。
  """
  def publish_entry(%Entry{} = entry) do
    occurred_at =
      case entry.occurred_at do
        nil -> DateTime.utc_now() |> DateTime.to_iso8601()
        dt -> DateTime.to_iso8601(dt)
      end

    entry
    |> Entry.changeset(%{"status" => "published", "occurred_at" => occurred_at})
    |> Repo.update()
  end

  @doc """
  エントリを削除する。
  """
  def delete_entry(%Entry{} = entry) do
    Repo.delete(entry)
  end

  @doc """
  エントリの changeset を生成する（フォーム用）。
  """
  def change_entry(%Entry{} = entry, attrs \\ %{}) do
    Entry.changeset(entry, attrs)
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
end
