defmodule WishlistsWeb.FolderLive.Show do
  alias Wishlists.Cards
  use WishlistsWeb, :live_view
  alias Wishlists.Folders
  alias Wishlists.Accounts.Guardian

  @impl true
  def mount(%{"id" => folder_id}, session, socket) do
    case Guardian.decode_and_verify(session["guardian_default_token"]) do
      {:ok, claims} ->
        {:ok, user} = Guardian.resource_from_claims(claims)
        folder_id = String.to_integer(folder_id)
        folder = Folders.get_folder!(folder_id)

        if folder.user_id == user.id do
          cards = Cards.list_folder_cards(folder_id)

          {:ok,
           socket
           |> assign(current_user: user)
           |> assign(folder: folder)
           |> assign(cards: cards)
           |> assign(page_title: folder.name)
           |> assign(show_modal: false)}
        else
          {:ok,
           socket
           |> put_flash(:error, "You don't have access to this folder")
           |> redirect(to: ~p"/dashboard")}
        end

      _ ->
        {:ok,
         socket
         |> put_flash(:error, "You must log in to access this page")
         |> redirect(to: ~p"/")}
    end
  end

  @impl true
  def handle_event("edit_folder", _, socket) do
    {:noreply,
     socket
     |> assign(:modal_title, "Edit Folder")
     |> assign(:submit_button_text, "Save Changes")
     |> assign(:action, :edit)
     |> assign(:show_modal, true)}
  end

  @impl true
  def handle_event("delete_folder", _, socket) do
    case Folders.delete_folder(socket.assigns.folder) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Folder deleted successfully")
         |> redirect(to: ~p"/dashboard")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not delete folder")
         |> redirect(to: ~p"/dashboard")}
    end
  end

  @impl true
  def handle_event("reorder_card", %{"card_id" => card_id, "position" => position}, socket) do
    card_id = String.to_integer(card_id)
    folder_id = socket.assigns.folder.id

    with :ok <- Cards.reorder_card(card_id, position, folder_id) do
      cards = Cards.list_folder_cards(folder_id)
      {:noreply, assign(socket, :cards, cards)}
    else
      {:error, reason} ->
        Logger.error("Failed to reorder card in folder: #{inspect(reason)}")
        {:noreply, put_flash(socket, :error, "Failed to reorder card")}
    end
  end

  @impl true
  def handle_info(:close_modal, socket) do
    {:noreply, assign(socket, show_modal: false)}
  end

  @impl true
  def handle_info({:folder_updated, folder}, socket) do
    {:noreply,
     socket
     |> assign(folder: folder)
     |> assign(show_modal: false)
     |> put_flash(:info, "Folder updated successfully")}
  end
end
