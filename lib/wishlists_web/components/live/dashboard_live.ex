defmodule WishlistsWeb.DashboardLive do
  use WishlistsWeb, :live_view
  alias Wishlists.{Folders, Cards}
  alias Wishlists.Folders.Folder
  alias Wishlists.Cards.Card
  require Logger

  on_mount {WishlistsWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, session, socket) do
    if socket.assigns.current_user do
      locale = session["locale"] || "en"
      Gettext.put_locale(WishlistsWeb.Gettext, locale)

      folders = Folders.list_user_folders(socket.assigns.current_user.id)
      followed_folders = Folders.list_followed_folders(socket.assigns.current_user.id)

      folders_with_counts =
        Enum.map(folders, fn folder ->
          card_count = Folders.get_folder_card_count(folder.id)
          Map.put(folder, :card_count, card_count)
        end)

      followed_folders_with_counts =
        Enum.map(followed_folders, fn folder ->
          card_count = Folders.get_folder_card_count(folder.id)
          Map.put(folder, :card_count, card_count)
        end)

      cards = Cards.list_unassigned_cards(socket.assigns.current_user.id)

      {:ok,
       socket
       |> assign(folders: folders_with_counts)
       |> assign(followed_folders: followed_folders_with_counts)
       |> assign(cards: cards)
       |> assign(show_modal: false)
       |> assign(modal_type: nil)
       |> assign(current_filter: "all")
       |> assign(show_folders_panel: false)
       |> assign(locale: locale)}
    else
      {:ok,
       socket
       |> put_flash(:error, "Please log in to access this page")
       |> redirect(to: ~p"/")}
    end
  end

  # Add this handler
  @impl true
  def handle_event("toggle_folders_panel", _, socket) do
    {:noreply, assign(socket, show_folders_panel: !socket.assigns.show_folders_panel)}
  end

  @impl true
  def handle_event("new_folder", _params, socket) do
    {:noreply,
     socket
     |> assign(:folder, %Folder{})
     |> assign(:modal_title, gettext("Create New Folder"))
     |> assign(:submit_button_text, gettext("Create"))
     |> assign(:action, :new)
     |> assign(:modal_type, :folder)
     |> assign(:show_modal, true)}
  end

  @impl true
  def handle_event("new_card", _params, socket) do
    {:noreply,
     socket
     |> assign(:card, %Card{})
     |> assign(:modal_title, gettext("Create A Wish!"))
     |> assign(:submit_button_text, gettext("Create"))
     |> assign(:action, :new)
     |> assign(:modal_type, :card)
     |> assign(:show_modal, true)}
  end

  @impl true
  def handle_event("assign_card", %{"card_id" => card_id, "folder_id" => folder_id}, socket) do
    Logger.info("Received assign_card event with card_id: #{card_id}, folder_id: #{folder_id}")

    case Cards.assign_card_to_folder(card_id, folder_id) do
      {:ok, _folder_card} ->
        cards = Cards.list_unassigned_cards(socket.assigns.current_user.id)
        folders = Folders.list_user_folders(socket.assigns.current_user.id)

        folders_with_counts =
          Enum.map(folders, fn folder ->
            card_count = Folders.get_folder_card_count(folder.id)
            Map.put(folder, :card_count, card_count)
          end)

        {:noreply,
         socket
         |> assign(cards: cards)
         |> assign(folders: folders_with_counts)
         |> put_flash(:info, "Card assigned to folder successfully")}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  def handle_event("edit_card", %{"id" => id}, socket) do
    card = Cards.get_card!(id)

    {:noreply,
     socket
     |> assign(:card, card)
     |> assign(:modal_title, gettext("Edit Card"))
     |> assign(:submit_button_text, gettext("Save Changes"))
     |> assign(:action, :edit)
     |> assign(:modal_type, :card)
     |> assign(:show_modal, true)}
  end

  def handle_event("delete_card", %{"id" => id}, socket) do
    card = Cards.get_card!(id)

    case Cards.delete_card(card) do
      {:ok, _deleted_card} ->
        cards = Cards.list_unassigned_cards(socket.assigns.current_user.id)

        {:noreply,
         socket
         |> assign(:cards, cards)
         |> put_flash(:info, "Card deleted successfully")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to delete card")}
    end
  end

  def handle_event("cancel_delete", _, socket) do
    {:noreply,
     socket
     |> assign(:show_modal, false)
     |> assign(:modal_type, nil)
     |> assign(:card_to_delete, nil)}
  end

  def handle_event("confirm_delete", %{"id" => id}, socket) do
    card = Cards.get_card!(id)

    case Cards.delete_card(card) do
      {:ok, _deleted_card} ->
        cards = Cards.list_unassigned_cards(socket.assigns.current_user.id)

        {:noreply,
         socket
         |> assign(:cards, cards)
         |> assign(:show_modal, false)
         |> assign(:modal_type, nil)
         |> assign(:card_to_delete, nil)
         |> put_flash(:info, "Wish deleted successfully")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> assign(:show_modal, false)
         |> assign(:modal_type, nil)
         |> assign(:card_to_delete, nil)
         |> put_flash(:error, "Failed to delete wish")}
    end
  end

  def handle_event("reorder_card", %{"card_id" => card_id, "position" => position}, socket) do
    card_id = String.to_integer(card_id)

    # Handle any return value from reorder_card
    with :ok <- Cards.reorder_card(card_id, position) do
      cards = Cards.list_unassigned_cards(socket.assigns.current_user.id)
      {:noreply, assign(socket, :cards, cards)}
    else
      {:error, reason} ->
        Logger.error("Failed to reorder card: #{inspect(reason)}")
        {:noreply, put_flash(socket, :error, "Failed to reorder card")}
    end
  end

  def handle_event("filter_folders", %{"filter" => filter}, socket) do
    {:noreply, assign(socket, :current_filter, filter)}
  end

  @impl true
  def handle_info(:close_modal, socket) do
    {:noreply, assign(socket, show_modal: false, modal_type: nil)}
  end

  @impl true
  def handle_info({:folder_created}, socket) do
    folders = Folders.list_user_folders(socket.assigns.current_user.id)

    folders_with_counts =
      Enum.map(folders, fn folder ->
        card_count = Folders.get_folder_card_count(folder.id)
        Map.put(folder, :card_count, card_count)
      end)

    {:noreply,
     socket
     |> assign(folders: folders_with_counts)
     |> assign(show_modal: false)
     |> assign(modal_type: nil)
     |> put_flash(:info, "Folder created successfully")}
  end

  @impl true
  def handle_info({:card_created}, socket) do
    cards = Cards.list_unassigned_cards(socket.assigns.current_user.id)

    {:noreply,
     socket
     |> assign(cards: cards)
     |> assign(show_modal: false)
     |> assign(modal_type: nil)
     |> put_flash(:info, gettext("Card created successfully"))}
  end

  @impl true
  def handle_info({:card_updated}, socket) do
    cards = Cards.list_unassigned_cards(socket.assigns.current_user.id)

    {:noreply,
     socket
     |> assign(cards: cards)
     |> assign(show_modal: false)
     |> assign(modal_type: nil)
     |> put_flash(:info, "Card updated successfully")}
  end

  def handle_info({:new_notification}, socket) do
    {:noreply, socket}
  end

  defp filter_folders(folders, followed_folders, "all"), do: folders ++ followed_folders
  defp filter_folders(folders, _followed_folders, "own"), do: folders
  defp filter_folders(_folders, followed_folders, "shared"), do: followed_folders

  defp get_folder_path(folder, current_user) do
    cond do
      folder.user_id == current_user.id ->
        ~p"/folders/#{folder.id}"

      true ->
        case Folders.get_shared_folder_by_folder_id(folder.id) do
          %{share_token: token} -> ~p"/shared/#{token}"
          nil -> ~p"/folders/#{folder.id}"
        end
    end
  end
end
