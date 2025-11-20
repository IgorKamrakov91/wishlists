defmodule Wishlists.Repo.Migrations.AddTelegramFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :telegram_id, :bigint
      add :telegram_username, :string
      add :telegram_photo_url, :string
      add :auth_provider, :string, null: false, default: "email"
    end

    create unique_index(:users, [:telegram_id], where: "telegram_id IS NOT NULL")
  end
end
