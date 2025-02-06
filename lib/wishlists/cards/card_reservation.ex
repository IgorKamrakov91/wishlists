defmodule Wishlists.Cards.CardReservation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "card_reservations" do
    belongs_to :folder_card, Wishlists.Cards.FolderCard
    belongs_to :reserved_by_user, Wishlists.Accounts.User
    belongs_to :reserved_by_guest, Wishlists.Accounts.GuestViewer
    field :reserver_name, :string
    field :status, :string, default: "reserved"

    timestamps()
  end

  def changeset(card_reservation, attrs) do
    card_reservation
    |> cast(attrs, [
      :folder_card_id,
      :reserved_by_user_id,
      :reserved_by_guest_id,
      :reserver_name,
      :status
    ])
    |> validate_required([:folder_card_id])
    |> unique_constraint(:folder_card_id)
  end
end
