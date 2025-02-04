defmodule Wishlists.Repo.Migrations.CreateSharedFolders do
  use Ecto.Migration

  def change do
    create table(:shared_folders) do
      add :folder_id, references(:folders, on_delete: :delete_all), null: false
      add :share_token, :string, null: false
      add :expires_at, :utc_datetime

      timestamps()
    end

    create unique_index(:shared_folders, [:share_token])
    create index(:shared_folders, [:folder_id])
  end
end
