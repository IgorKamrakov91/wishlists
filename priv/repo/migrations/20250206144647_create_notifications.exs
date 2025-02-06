defmodule Wishlists.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :type, :string, null: false
      add :title, :string, null: false
      add :message, :text
      add :read_at, :utc_datetime
      add :data, :map, default: %{}

      timestamps()
    end

    create index(:notifications, [:user_id])
    create index(:notifications, [:read_at])
  end
end
