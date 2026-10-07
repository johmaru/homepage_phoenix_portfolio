defmodule HomepagePhoenix.Blog.PostTag do
  use Ecto.Schema

  alias HomepagePhoenix.Blog.{Post, Tag}

  @primary_key false
  schema "post_tags" do
    belongs_to(:post, Post, primary_key: true)
    belongs_to(:tag, Tag, primary_key: true)
  end
end
