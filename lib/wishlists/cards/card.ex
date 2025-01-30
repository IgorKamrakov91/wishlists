defmodule Wishlists.Cards.Card do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cards" do
    field :title, :string
    field :description, :string
    field :image_url, :string
    field :link_url, :string
    field :price, :float
    belongs_to :user, Wishlists.Accounts.User

    many_to_many :folders, Wishlists.Folders.Folder, join_through: "folder_cards"

    has_many :folder_cards, Wishlists.Cards.FolderCard

    timestamps()
  end

  def changeset(card, attrs) do
    card
    |> cast(attrs, [:title, :description, :image_url, :link_url, :user_id, :price])
    |> validate_required([:title, :user_id])
    |> validate_length(:title, min: 1, max: 100)
    |> validate_length(:description, max: 500)
    |> validate_url(:image_url)
    |> validate_url(:link_url)
  end

  defp validate_url(changeset, field) do
    validate_change(changeset, field, fn _, url ->
      if is_nil(url) or valid_url?(url) do
        []
      else
        [{field, "must be a valid URL"}]
      end
    end)
  end

  defp valid_url?(nil), do: true

  defp valid_url?(url) do
    uri = URI.parse(url)
    uri.scheme != nil && uri.host != nil
  end
end
