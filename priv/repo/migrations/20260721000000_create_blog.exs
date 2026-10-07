defmodule HomepagePhoenix.Repo.Migrations.CreateBlog do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :is_admin, :boolean, null: false, default: false
    end

    create table(:posts) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :title, :string, null: false
      add :slug, :string, null: false
      add :body_md, :text, null: false
      add :status, :string, null: false, default: "draft"
      add :published_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:posts, [:slug])
    create index(:posts, [:published_at])
    create index(:posts, [:user_id])

    create table(:tags) do
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:tags, [:name])

    create table(:post_tags, primary_key: false) do
      add :post_id, references(:posts, on_delete: :delete_all), primary_key: true
      add :tag_id, references(:tags, on_delete: :delete_all), primary_key: true
    end

    create index(:post_tags, [:tag_id])
  end
end
