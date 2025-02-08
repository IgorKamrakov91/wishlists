defmodule Wishlists.Repo.Migrations.CreateFollowedFolders do
  use Ecto.Migration

  def change do
    create table(:followed_folders) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :folder_id, references(:folders, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:followed_folders, [:user_id, :folder_id])
  end
end
