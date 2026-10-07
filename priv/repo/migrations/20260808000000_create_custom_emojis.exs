defmodule HomepagePhoenix.Repo.Migrations.CreateCustomEmojis do
  use Ecto.Migration

  def change do
    create table(:custom_emojis) do
      add :name, :string, null: false
      add :image_url, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:custom_emojis, [:name])
    create index(:custom_emojis, [:user_id])
  end
end
