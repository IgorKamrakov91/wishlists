defmodule Wishlists.Repo.Migrations.AddPositionToCards do
  use Ecto.Migration

  def change do
    alter table(:cards) do
      add :position, :integer
    end

    # Add position index
    create index(:cards, [:position])
  end
end
