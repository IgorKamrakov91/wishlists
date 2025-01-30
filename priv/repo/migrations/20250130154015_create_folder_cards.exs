defmodule Wishlists.Repo.Migrations.CreateFolderCards do
  use Ecto.Migration

  def change do
    create table(:folder_cards) do
      add :folder_id, references(:folders, on_delete: :delete_all), null: false
      add :card_id, references(:cards, on_delete: :delete_all), null: false
      add :position, :integer

      timestamps()
    end

    create index(:folder_cards, [:folder_id])
    create index(:folder_cards, [:card_id])
    create unique_index(:folder_cards, [:folder_id, :card_id])
  end
end
