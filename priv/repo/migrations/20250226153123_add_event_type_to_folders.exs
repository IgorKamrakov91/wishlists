defmodule Wishlists.Repo.Migrations.AddEventTypeToFolders do
  use Ecto.Migration

  def change do
    alter table(:folders) do
      add :event_type, :string
    end
  end
end
