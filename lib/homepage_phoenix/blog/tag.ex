defmodule HomepagePhoenix.Blog.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  alias HomepagePhoenix.Blog.PostTag

  schema "tags" do
    field(:name, :string)

    has_many(:post_tags, PostTag)
    has_many(:posts, through: [:post_tags, :post])

    timestamps(type: :utc_datetime)
  end

  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
