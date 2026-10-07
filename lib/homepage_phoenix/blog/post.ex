defmodule HomepagePhoenix.Blog.Post do
  use Ecto.Schema
  import Ecto.Changeset

  alias HomepagePhoenix.Accounts.User
  alias HomepagePhoenix.Blog.PostTag

  schema "posts" do
    field(:title, :string)
    field(:slug, :string)
    field(:body_md, :string)
    field(:status, :string, default: "draft")
    field(:published_at, :utc_datetime)

    belongs_to(:user, User)
    has_many(:post_tags, PostTag)
    has_many(:tags, through: [:post_tags, :tag])

    timestamps(type: :utc_datetime)
  end

  @doc """
  投稿作成・編集用の changeset。

  `user_id` は attrs から受け取らず、呼び出し側で `put_assoc` する
  （AGENTS.md のセキュリティ指針）。
  """
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :slug, :body_md, :status, :published_at])
    |> validate_required([:title, :body_md])
    |> validate_slug_required()
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/)
    |> validate_length(:slug, min: 3, max: 80)
    |> unique_constraint(:slug)
    |> validate_published_at()
  end

  # slug は必須。自動生成が空になるケース（日本語タイトル等）でも
  # ユーザー入力を促すため validate_required を付与。
  defp validate_slug_required(changeset) do
    case get_field(changeset, :slug) do
      value when is_binary(value) and value != "" -> changeset
      _ -> add_error(changeset, :slug, "必須です")
    end
  end

  # status=published のときは published_at を必須にする
  defp validate_published_at(changeset) do
    case get_field(changeset, :status) do
      "published" ->
        case get_field(changeset, :published_at) do
          nil -> add_error(changeset, :published_at, "公開日時が必要です")
          _ -> changeset
        end

      _ ->
        changeset
    end
  end
end
