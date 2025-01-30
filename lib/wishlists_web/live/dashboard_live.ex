defmodule WishlistsWeb.DashboardLive do
  use WishlistsWeb, :live_view
  alias Wishlists.Accounts.Guardian
  alias Wishlists.{Folders, Cards}
  alias Wishlists.Folders.Folder
  alias Wishlists.Cards.Card
  require Logger

  alias Phoenix.LiveView.JS

  @impl true
  def mount(_params, session, socket) do
    case Guardian.decode_and_verify(session["guardian_default_token"]) do
      {:ok, claims} ->
        {:ok, user} = Guardian.resource_from_claims(claims)
        folders = Folders.list_user_folders(user.id)
        cards = Cards.list_unassigned_cards(user.id)

        {:ok,
         socket
         |> assign(current_user: user)
         |> assign(folders: folders)
         |> assign(cards: cards)
         |> assign(show_modal: false)
         |> assign(modal_type: nil)}
    end
  end

  @impl true
  def handle_event("new_folder", _params, socket) do
    {:noreply,
     socket
     |> assign(:folder, %Folder{})
     |> assign(:modal_title, "Create New Folder")
     |> assign(:submit_button_text, "Create")
     |> assign(:action, :new)
     |> assign(:modal_type, :folder)
     |> assign(:show_modal, true)}
  end

  @impl true
  def handle_event("new_card", _params, socket) do
    {:noreply,
     socket
     |> assign(:card, %Card{})
     |> assign(:modal_title, "Create New Card")
     |> assign(:submit_button_text, "Create")
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

        {:noreply,
         socket
         |> assign(cards: cards)
         |> put_flash(:info, "Card assigned to folder successfully")}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(:close_modal, socket) do
    {:noreply, assign(socket, show_modal: false, modal_type: nil)}
  end

  @impl true
  def handle_info({:folder_created}, socket) do
    folders = Folders.list_user_folders(socket.assigns.current_user.id)

    {:noreply,
     socket
     |> assign(folders: folders)
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
     |> put_flash(:info, "Card created successfully")}
  end
end
