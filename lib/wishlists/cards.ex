defmodule Wishlists.Cards do
  import Ecto.Query
  alias Wishlists.Repo
  alias Wishlists.Cards.{Card, FolderCard}
  require Logger

  def list_user_cards(user_id) do
    Card
    |> where(user_id: ^user_id)
    |> order_by([c], c.inserted_at)
    |> Repo.all()
  end

  def list_unassigned_cards(user_id) do
    assigned_card_ids = Repo.all(from(fc in FolderCard, select: fc.card_id))

    from(c in Card,
      where: c.user_id == ^user_id and c.id not in ^assigned_card_ids,
      order_by: [asc: c.inserted_at]
    )
    |> Repo.all()
  end

  def get_card!(id), do: Repo.get!(Card, id)

  def create_card(attrs \\ %{}) do
    %Card{}
    |> Card.changeset(attrs)
    |> Repo.insert()
  end

  def update_card(%Card{} = card, attrs) do
    card
    |> Card.changeset(attrs)
    |> Repo.update()
  end

  def delete_card(%Card{} = card) do
    Repo.delete(card)
  end

  def change_card(%Card{} = card, attrs \\ %{}) do
    Card.changeset(card, attrs)
  end

  def assign_card_to_folder(card_id, folder_id, position \\ nil) do
    Logger.info("Assigning card #{card_id} to folder #{folder_id}")

    %FolderCard{}
    |> FolderCard.changeset(%{
      card_id: card_id,
      folder_id: folder_id,
      position: position
    })
    |> Repo.insert()
    |> case do
      {:ok, folder_card} = result ->
        Logger.info("Successfully created folder_card: #{inspect(folder_card)}")
        result

      {:error, changeset} = error ->
        Logger.error("Failed to create folder_card: #{inspect(changeset.errors)}")
        error
    end
  end

  def remove_card_from_folder(card_id, folder_id) do
    from(fc in FolderCard,
      where: fc.card_id == ^card_id and fc.folder_id == ^folder_id
    )
    |> Repo.delete_all()
  end
end
