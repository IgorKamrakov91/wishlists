defmodule Wishlists.Repo.Migrations.AddShareSlugToSharedFolders do
  use Ecto.Migration

  def change do
    alter table(:shared_folders) do
      add :share_slug, :string
    end

    create unique_index(:shared_folders, [:share_slug])
  end
end
