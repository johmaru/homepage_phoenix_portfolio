defmodule HomepagePhoenix.Activity.Entry do
  use Ecto.Schema
  import Ecto.Changeset

  alias HomepagePhoenix.Accounts.User

  schema "activity_entries" do
    field(:kind, :string)
    field(:title, :string)
    field(:body, :string)
    field(:status, :string, default: "draft")
    field(:occurred_at, :utc_datetime)

    belongs_to(:user, User)

    timestamps(type: :utc_datetime)
  end

  @doc """
  活動・更新エントリ作成・編集用の changeset。

  `user_id` は attrs から受け取らず、呼び出し側で `put_assoc` する
  （Blog.Post と同じセキュリティ指針）。
  """
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:kind, :title, :body, :status, :occurred_at])
    |> validate_required([:kind, :title, :body])
    |> validate_inclusion(:kind, ~w(activity update))
    |> validate_inclusion(:status, ~w(draft published))
    |> validate_length(:title, min: 1, max: 100)
    |> validate_length(:body, min: 1, max: 500)
    |> validate_occurred_at()
  end

  # status=published のときは occurred_at を必須にする
  defp validate_occurred_at(changeset) do
    case get_field(changeset, :status) do
      "published" ->
        case get_field(changeset, :occurred_at) do
          nil -> add_error(changeset, :occurred_at, "発生日時が必要です")
          _ -> changeset
        end

      _ ->
        changeset
    end
  end
end
