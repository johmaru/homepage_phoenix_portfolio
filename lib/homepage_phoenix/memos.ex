defmodule HomepagePhoenix.Memos do
  @moduledoc """
  テキストメモのコンテキスト。

  公開側クエリは `visibility == "public"` のメモだけを返す。
  """

  import Ecto.Query, warn: false

  alias HomepagePhoenix.Accounts.Scope
  alias HomepagePhoenix.Memos.Memo
  alias HomepagePhoenix.Repo

  @doc "公開一覧用に public メモを更新日時の降順で取得する。"
  def list_public_memos do
    from(m in Memo,
      where: m.visibility == "public",
      order_by: [desc: m.updated_at, desc: m.id]
    )
    |> Repo.all()
  end

  @doc "Sitemap 用に public メモの share_id と更新日時だけを取得する。"
  def list_public_memos_for_sitemap do
    from(m in Memo,
      where: m.visibility == "public",
      order_by: [desc: m.updated_at, desc: m.id],
      select: %{share_id: m.share_id, updated_at: m.updated_at}
    )
    |> Repo.all()
  end

  @doc "公開方法を問わず share_id でメモを取得する。"
  def get_memo_by_share_id!(share_id) do
    case Ecto.UUID.cast(share_id) do
      {:ok, share_id} -> Repo.get_by!(Memo, share_id: share_id)
      :error -> raise Ecto.NoResultsError, queryable: Memo
    end
  end

  @doc "管理画面用に全メモを更新日時の降順で取得する。"
  def list_admin_memos do
    from(m in Memo, order_by: [desc: m.updated_at, desc: m.id])
    |> Repo.all()
  end

  @doc "管理画面用に id でメモを取得する。"
  def get_admin_memo!(id) do
    Repo.get!(Memo, id)
  end

  @doc "メモを作成する。所有者は current scope の user から設定する。"
  def create_memo(%Scope{user: user}, attrs) do
    %Memo{}
    |> Memo.changeset(Map.drop(attrs, [:user_id, :share_id, "user_id", "share_id"]))
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  @doc "メモを更新する。所有者と share_id は attrs から変更できない。"
  def update_memo(%Memo{} = memo, attrs) do
    memo
    |> Memo.changeset(Map.drop(attrs, [:user_id, :share_id, "user_id", "share_id"]))
    |> Repo.update()
  end

  @doc "メモを削除する。"
  def delete_memo(%Memo{} = memo) do
    Repo.delete(memo)
  end

  @doc "メモの changeset を生成する（フォーム用）。"
  def change_memo(%Memo{} = memo, attrs \\ %{}) do
    Memo.changeset(memo, attrs)
  end
end
