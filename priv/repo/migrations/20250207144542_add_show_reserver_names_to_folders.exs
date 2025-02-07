defmodule Wishlists.Repo.Migrations.AddShowReserverNamesToFolders do
  use Ecto.Migration

  def change do
    alter table(:folders) do
      add :show_reserver_names, :boolean, default: false
    end
  end
end
