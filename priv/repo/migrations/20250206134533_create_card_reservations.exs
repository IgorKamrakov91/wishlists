defmodule Wishlists.Repo.Migrations.CreateCardReservations do
  use Ecto.Migration

  def change do
    create table(:card_reservations) do
      add :folder_card_id, references(:folder_cards, on_delete: :delete_all), null: false
      add :reserved_by_user_id, references(:users, on_delete: :nilify_all)
      add :reserved_by_guest_id, references(:guest_viewers, on_delete: :nilify_all)
      add :reserver_name, :string
      add :status, :string, default: "reserved"

      timestamps()
    end

    create unique_index(:card_reservations, [:folder_card_id])
  end
end
