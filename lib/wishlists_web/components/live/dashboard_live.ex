defmodule WishlistsWeb.DashboardLive do
  use WishlistsWeb, :live_view
  alias Wishlists.{Folders, Cards}
  alias Wishlists.Folders.Folder
  alias Wishlists.Cards.Card
  require Logger

  on_mount {WishlistsWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, session, socket) do
    # on_mount :ensure_authenticated already verified authentication
    # so current_user should always be present here
    locale = session["locale"] || "ru"
    Gettext.put_locale(WishlistsWeb.Gettext, locale)

    current_user =
      socket.assigns.current_user
      |> Wishlists.Repo.preload(:account)

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

    if connected?(socket) do
      :timer.send_interval(60_000, self(), :update_times)
    end

    {:ok,
     socket
     |> assign(current_user: current_user)
     |> assign(folders: folders_with_counts)
     |> assign(followed_folders: followed_folders_with_counts)
     |> assign(cards: cards)
     |> assign(show_modal: false)
     |> assign(modal_type: nil)
     |> assign(current_filter: "all")
     |> assign(show_folders_panel: false)
     |> assign(current_time: DateTime.utc_now())
     |> assign(locale: locale)
     |> assign(show_folders_for_card: nil)}
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
     |> assign(:show_modal, true)
     |> assign(:parent_pid, self())}
  end

  @impl true
  def handle_event("assign_card", params, socket) do
    card_id = params["card_id"]
    folder_id = String.to_integer(params["folder_id"])
    all_folders = socket.assigns.folders ++ socket.assigns.followed_folders
    folder = Enum.find(all_folders, &(&1.id == folder_id))

    cond do
      folder && folder.user_id == socket.assigns.current_user.id ->
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
             |> assign(:show_folders_for_card, nil)}

          {:error, _changeset} ->
            {:noreply,
             socket
             |> put_flash(:error, gettext("Failed to add wish to wishlist"))}
        end

      true ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("You don't have permission to add cards to this folder"))}
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
     |> assign(:show_modal, true)
     |> assign(:parent_pid, self())}
  end

  def handle_event("filter_folders", %{"filter" => filter}, socket) do
    {:noreply, assign(socket, :current_filter, filter)}
  end

  def handle_event("show_error", %{"message" => message}, socket) do
    {:noreply, put_flash(socket, :error, message)}
  end

  def handle_event("toggle_folders", %{"card_id" => card_id}, socket) do
    current_card = socket.assigns.show_folders_for_card
    new_card = if current_card == card_id, do: nil, else: card_id

    {:noreply, assign(socket, :show_folders_for_card, new_card)}
  end

  def handle_event("delete_card", %{"id" => id, "value" => _}, socket) do
    card = Cards.get_card!(id)

    case Cards.delete_card(card) do
      {:ok, _deleted_card} ->
        cards = Cards.list_unassigned_cards(socket.assigns.current_user.id)

        {:noreply,
         socket
         |> assign(:cards, cards)
         |> assign(:show_modal, false)
         |> assign(:modal_type, nil)}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> assign(:show_modal, false)
         |> assign(:modal_type, nil)
         |> put_flash(:error, gettext("Failed to delete wish"))}
    end
  end

  def handle_info({:delete_card, id}, socket) do
    card = Cards.get_card!(id)

    case Cards.delete_card(card) do
      {:ok, _deleted_card} ->
        cards = Cards.list_unassigned_cards(socket.assigns.current_user.id)

        {:noreply,
         socket
         |> assign(:cards, cards)
         |> assign(:show_modal, false)
         |> assign(:modal_type, nil)}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> assign(:show_modal, false)
         |> assign(:modal_type, nil)
         |> put_flash(:error, gettext("Failed to delete wish"))}
    end
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
     |> assign(modal_type: nil)}
  end

  @impl true
  def handle_info({:card_created}, socket) do
    cards = Cards.list_unassigned_cards(socket.assigns.current_user.id)

    {:noreply,
     socket
     |> assign(cards: cards)
     |> assign(show_modal: false)
     |> assign(modal_type: nil)
     |> push_event("trigger_card_confetti", %{})
     |> push_event("init_new_card", %{})}
  end

  @impl true
  def handle_info({:card_updated}, socket) do
    cards = Cards.list_unassigned_cards(socket.assigns.current_user.id)

    {:noreply,
     socket
     |> assign(cards: cards)
     |> assign(show_modal: false)
     |> assign(modal_type: nil)}
  end

  def handle_info({:new_notification}, socket) do
    {:noreply, socket}
  end

  def handle_info(:update_times, socket) do
    {:noreply, assign(socket, current_time: DateTime.utc_now())}
  end

  # Оставляем стандартный update для других случаев
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  defp filter_folders(folders, followed_folders, "all"), do: folders ++ followed_folders
  defp filter_folders(folders, _followed_folders, "own"), do: folders
  defp filter_folders(_folders, followed_folders, "shared"), do: followed_folders

  defp get_folder_path(folder, current_user) do
    cond do
      is_nil(folder) || is_nil(folder.id) ->
        ~p"/dashboard"

      folder.user_id == current_user.id ->
        ~p"/folders/#{folder.id}"

      true ->
        case Folders.get_shared_folder_by_folder_id(folder.id) do
          %{share_slug: slug} when not is_nil(slug) ->
            ~p"/shared/#{slug}"

          %{share_token: token} when not is_nil(token) ->
            ~p"/shared/t/#{token}"

          _ ->
            ~p"/folders/#{folder.id}"
        end
    end
  end

  defp format_event_date(nil), do: gettext("No event date set")

  defp format_event_date(event_date) do
    today = Date.utc_today()
    days_until = Date.diff(event_date, today)

    cond do
      days_until < 0 ->
        gettext("Event has passed %{icon}", icon: "🗓️")

      days_until == 0 ->
        gettext("Event is today %{icon}", icon: "✨")

      days_until == 1 ->
        gettext("Event is tomorrow %{icon}", icon: "🎉")

      true ->
        gettext("%{days} days remaining", days: days_until)
    end
  end
end
