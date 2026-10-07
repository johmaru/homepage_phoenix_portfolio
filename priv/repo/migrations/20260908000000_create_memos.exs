defmodule HomepagePhoenix.Repo.Migrations.CreateMemos do
  use Ecto.Migration

  def change do
    create table(:memos) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :share_id, :uuid, null: false
      add :title, :string, null: false
      add :body, :text, null: false
      add :visibility, :string, null: false, default: "public"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:memos, [:share_id])
    create index(:memos, [:user_id])
    create index(:memos, [:visibility])
  end
end
