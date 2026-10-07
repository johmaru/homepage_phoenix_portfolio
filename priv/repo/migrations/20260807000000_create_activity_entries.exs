defmodule HomepagePhoenix.Repo.Migrations.CreateActivityEntries do
  use Ecto.Migration

  def change do
    create table(:activity_entries) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :kind, :string, null: false
      add :title, :string, null: false
      add :body, :text, null: false
      add :status, :string, null: false, default: "draft"
      add :occurred_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:activity_entries, [:occurred_at])
    create index(:activity_entries, [:user_id])
    create index(:activity_entries, [:status])
  end
end
