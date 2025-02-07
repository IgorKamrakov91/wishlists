defmodule Wishlists.Repo.Migrations.AddEventDateToFolders do
  use Ecto.Migration

  def change do
    alter table(:folders) do
      add :event_date, :date
    end
  end
end
