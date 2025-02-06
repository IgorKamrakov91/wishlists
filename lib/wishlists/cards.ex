defmodule Wishlists.Cards do
  import Ecto.Query
  alias Wishlists.Repo
  alias Wishlists.Cards.{Card, CardReservation, FolderCard}
  require Logger

  def list_user_cards(user_id) do
    Card
    |> where(user_id: ^user_id)
    |> order_by([c], asc: c.position)
    |> Repo.all()
  end

  def list_folder_cards(folder_id) do
    FolderCard
    |> where([fc], fc.folder_id == ^folder_id)
    |> order_by([fc], asc: fc.position)
    |> preload([:card, :reservation])
    |> Repo.all()
  end

  def list_unassigned_cards(user_id) do
    assigned_card_ids = Repo.all(from(fc in FolderCard, select: fc.card_id))

    from(c in Card,
      where: c.user_id == ^user_id and c.id not in ^assigned_card_ids,
      order_by: [asc: :position, asc: :inserted_at]
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

  def reserve_card(folder_card_id, attrs) do
    %CardReservation{}
    |> CardReservation.changeset(Map.put(attrs, "folder_card_id", folder_card_id))
    |> Repo.insert()
  end

  def unreserve_card(folder_card_id) do
    case Repo.get_by(CardReservation, folder_card_id: folder_card_id) do
      nil -> {:error, :not_found}
      reservation -> Repo.delete(reservation)
    end
  end

  def get_card_reservation(folder_card_id) do
    Repo.get_by(CardReservation, folder_card_id: folder_card_id)
  end

  def get_folder_card!(id) do
    FolderCard
    |> where([fc], fc.id == ^id)
    |> preload([:card])
    |> Repo.one!()
  end

  def delete_card(%Card{} = card) do
    Repo.delete(card)
  end

  def change_card(%Card{} = card, attrs \\ %{}) do
    Card.changeset(card, attrs)
  end

  def assign_card_to_folder(card_id, folder_id, position \\ nil) do
    Logger.info("Assigning card #{card_id} to folder #{folder_id}")

    # First check if the association already exists
    case Repo.get_by(FolderCard, card_id: card_id, folder_id: folder_id) do
      nil ->
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

      folder_card ->
        # If it already exists, return ok tuple
        {:ok, folder_card}
    end
  end

  def remove_card_from_folder(card_id, folder_id) do
    query =
      from fc in "folder_cards",
        where: fc.card_id == ^card_id and fc.folder_id == ^folder_id

    case Repo.delete_all(query) do
      {n, _} when n > 0 -> {:ok, :removed}
      {0, _} -> {:error, :not_found}
    end
  rescue
    e ->
      {:error, e}
  end

  def reorder_card(card_id, new_position, folder_id \\ nil) do
    case Repo.transaction(fn ->
           card = get_card!(card_id)

           query =
             if folder_id do
               # For folder cards, use the FolderCard join table
               from c in Card,
                 join: fc in FolderCard,
                 on: c.id == fc.card_id,
                 where: fc.folder_id == ^folder_id,
                 order_by: [asc: fc.position]
             else
               # For unassigned cards
               from c in Card,
                 where: c.user_id == ^card.user_id,
                 where:
                   c.id not in subquery(
                     from fc in FolderCard,
                       select: fc.card_id
                   ),
                 order_by: [asc: c.position]
             end

           cards = Repo.all(query)

           # Remove the card being moved
           remaining_cards = Enum.reject(cards, &(&1.id == card_id))

           # Insert the card at the new position
           {before_cards, after_cards} = Enum.split(remaining_cards, new_position - 1)
           reordered_cards = before_cards ++ [card] ++ after_cards

           # Update positions based on context
           if folder_id do
             # Update FolderCard positions
             reordered_cards
             |> Enum.with_index(1)
             |> Enum.each(fn {card, index} ->
               from(fc in FolderCard,
                 where: fc.card_id == ^card.id and fc.folder_id == ^folder_id
               )
               |> Repo.update_all(set: [position: index])
             end)
           else
             # Update Card positions directly
             reordered_cards
             |> Enum.with_index(1)
             |> Enum.each(fn {card, index} ->
               card
               |> Ecto.Changeset.change(%{position: index})
               |> Repo.update!()
             end)
           end
         end) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end
end
