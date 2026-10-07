defmodule HomepagePhoenix.Emojis.CustomEmoji do
  use Ecto.Schema
  import Ecto.Changeset

  alias HomepagePhoenix.Accounts.User

  schema "custom_emojis" do
    field(:name, :string)
    field(:image_url, :string)

    belongs_to(:user, User)

    timestamps(type: :utc_datetime)
  end

  @doc """
  カスタム絵文字の作成・編集用 changeset。

  `user_id` は attrs から受け取らず、呼び出し側で `put_assoc` する
  （Blog.Post / Activity.Entry と同じセキュリティ指針）。
  """
  def changeset(emoji, attrs) do
    emoji
    |> cast(attrs, [:name, :image_url])
    |> validate_required([:name, :image_url])
    |> validate_format(:name, ~r/^[a-z0-9_]+$/, message: "半角英数字とアンダースコアのみ")
    |> validate_length(:name, min: 2, max: 32)
    |> unique_constraint(:name)
  end
end
