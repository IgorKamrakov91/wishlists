defmodule Wishlists.Repo.Migrations.IncreaseCardUrlLength do
  use Ecto.Migration

  def change do
    alter table(:cards) do
      modify :link_url, :string, size: 2000
      modify :image_url, :string, size: 2000
    end
  end
end
