defmodule Wishlists.Cards.FolderCard do
  use Ecto.Schema
  import Ecto.Changeset

  schema "folder_cards" do
    belongs_to :folder, Wishlists.Folders.Folder
    belongs_to :card, Wishlists.Cards.Card
    field :position, :integer

    has_one :reservation, Wishlists.Cards.CardReservation

    timestamps()
  end

  def changeset(folder_card, attrs) do
    folder_card
    |> cast(attrs, [:folder_id, :card_id, :position])
    |> validate_required([:folder_id, :card_id])
    |> unique_constraint([:folder_id, :card_id])
    |> foreign_key_constraint(:folder_id)
    |> foreign_key_constraint(:card_id)
  end
end
