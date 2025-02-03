defmodule Wishlists.Folders.Folder do
  use Ecto.Schema
  import Ecto.Changeset

  schema "folders" do
    field :name, :string
    field :description, :string
    belongs_to :user, Wishlists.Accounts.User

    many_to_many :cards, Wishlists.Cards.Card,
      join_through: "folder_cards",
      on_delete: :delete_all

    timestamps()
  end

  def changeset(folder, attrs) do
    folder
    |> cast(attrs, [:name, :description, :user_id])
    |> validate_required([:name, :user_id])
    |> validate_length(:name, min: 1, max: 50)
    |> validate_length(:description, max: 40)
  end
end
