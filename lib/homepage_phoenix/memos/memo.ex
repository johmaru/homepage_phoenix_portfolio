defmodule HomepagePhoenix.Memos.Memo do
  use Ecto.Schema
  import Ecto.Changeset

  alias HomepagePhoenix.Accounts.User

  schema "memos" do
    field(:share_id, Ecto.UUID, autogenerate: true)
    field(:title, :string)
    field(:body, :string)
    field(:visibility, :string, default: "public")

    belongs_to(:user, User)

    timestamps(type: :utc_datetime)
  end

  @doc """
  メモの作成・編集用 changeset。

  `user_id` と `share_id` は attrs から受け取らず、呼び出し側で設定する。
  """
  def changeset(memo, attrs) do
    memo
    |> cast(attrs, [:title, :body, :visibility])
    |> validate_required([:title, :body, :visibility])
    |> validate_length(:title, min: 1, max: 100)
    |> validate_inclusion(:visibility, ~w(public unlisted))
    |> unique_constraint(:share_id)
  end
end
