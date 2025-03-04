defmodule Wishlists.Repo.Migrations.UpdatePriceForCards do
  use Ecto.Migration

  def change do
    alter table(:cards) do
      modify :price, :decimal, precision: 10, scale: 2
    end
  end
end
