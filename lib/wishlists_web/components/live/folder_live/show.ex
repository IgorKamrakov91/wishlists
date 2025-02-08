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

          shared_folder = get_or_create_shared_folder(folder_id)
          share_url = generate_share_url(shared_folder.share_token)

          {:ok,
           socket
           |> assign(current_user: user)
           |> assign(folder: folder)
           |> assign(cards: cards)
           |> assign(page_title: folder.name)
           |> assign(show_modal: false)
           |> assign(show_share_modal: false)
           |> assign(share_url: share_url)
           |> assign(show_delete_modal: false)}
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

  defp get_or_create_shared_folder(folder_id) do
    case Folders.get_shared_folder_by_folder_id(folder_id) do
      nil ->
        {:ok, shared_folder} = Folders.create_shared_folder(folder_id)
        shared_folder

      shared_folder ->
        shared_folder
    end
  end

  defp generate_share_url(token) do
    WishlistsWeb.Endpoint.url() <> "/shared/" <> token
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
    folder = socket.assigns.folder

    case Folders.delete_folder(folder) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Folder deleted successfully")
         |> redirect(to: ~p"/dashboard")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not delete folder")
         |> assign(show_delete_modal: false)}
    end
  end

  def handle_event("create_share_link", _, socket) do
    folder = socket.assigns.folder

    case Folders.create_shared_folder(folder.id) do
      {:ok, shared_folder} ->
        share_url = WishlistsWeb.Endpoint.url() <> "/shared/" <> shared_folder.share_token

        # Just set the URL, copying will be handled by JavaScript
        {:noreply,
         socket
         |> assign(:share_url, share_url)
         |> assign(:show_share_modal, true)
         |> handle_share_modal_timeout()}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not create share link")}
    end
  end

  def handle_event("share_folder", _, socket) do
    {:noreply,
     socket
     |> assign(:show_share_modal, true)
     |> handle_share_modal_timeout()}
  end

  @impl true
  def handle_event("reorder_card", %{"card_id" => card_id, "position" => position}, socket) do
    card_id = String.to_integer(card_id)
    folder_id = socket.assigns.folder.id

    with :ok <- Cards.reorder_card(card_id, position, folder_id) do
      cards = Cards.list_folder_cards(folder_id)
      {:noreply, assign(socket, :cards, cards)}
    else
      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to reorder card")}
    end
  end

  @impl true
  def handle_event("remove_card", %{"card_id" => card_id}, socket) do
    card_id = String.to_integer(card_id)
    folder_id = socket.assigns.folder.id

    case Cards.remove_card_from_folder(card_id, folder_id) do
      {:ok, :removed} ->
        cards = Cards.list_folder_cards(folder_id)

        {:noreply,
         socket
         |> assign(:cards, cards)
         |> put_flash(:info, "Card removed from folder")}

      {:error, :not_found} ->
        {:noreply,
         socket
         |> put_flash(:error, "Card was already removed from folder")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not remove card from folder")}
    end
  end

  @impl true
  def handle_event("show_delete_modal", _, socket) do
    {:noreply, assign(socket, show_delete_modal: true)}
  end

  @impl true
  def handle_event("hide_delete_modal", _, socket) do
    {:noreply, assign(socket, show_delete_modal: false)}
  end

  def handle_event("copy_to_clipboard", _, socket) do
    {:noreply,
     socket
     |> push_event("do_copy", %{text: socket.assigns.share_url})}
  end

  def handle_event("copied_to_clipboard", _, socket) do
    {:noreply,
     socket
     |> assign(:show_share_modal, true)
     |> handle_share_modal_timeout()}
  end

  def handle_event("approve_card", %{"id" => card_id}, socket) do
    card_id = String.to_integer(card_id)

    case Cards.approve_card(card_id) do
      {:ok, _card} ->
        cards = Cards.list_folder_cards(socket.assigns.folder.id)

        {:noreply,
         socket
         |> assign(:cards, cards)
         |> put_flash(:info, "Gift suggestion approved successfully!")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to approve gift suggestion")}
    end
  end

  def handle_event("reject_card", %{"id" => card_id}, socket) do
    card_id = String.to_integer(card_id)

    case Cards.reject_card(card_id) do
      {:ok, _card} ->
        cards = Cards.list_folder_cards(socket.assigns.folder.id)

        {:noreply,
         socket
         |> assign(:cards, cards)
         |> put_flash(:info, "Gift suggestion rejected successfully!")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to reject gift suggestion")}
    end
  end

  defp handle_share_modal_timeout(socket) do
    Process.send_after(self(), :hide_share_modal, 3000)
    socket
  end

  def handle_info(:hide_share_modal, socket) do
    {:noreply, assign(socket, :show_share_modal, false)}
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

  def handle_info({:new_notification}, socket) do
    {:noreply, socket}
  end

  defp get_suggester_name(card) do
    cond do
      card.suggested_by_user_id ->
        user = Wishlists.Accounts.get_user!(card.suggested_by_user_id)
        user.email

      card.suggested_by_guest_id ->
        guest = Wishlists.Accounts.get_guest_viewer!(card.suggested_by_guest_id)
        "Guest: #{guest.name}"

      true ->
        "Unknown"
    end
  end
end
