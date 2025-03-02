defmodule Wishlists.Repo.Migrations.AddNotificationPreferencesToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :notification_preferences, :map,
        default: %{
          "cleanup_notifications" => true,
          "reservation_notifications" => true
        }
    end
  end
end
