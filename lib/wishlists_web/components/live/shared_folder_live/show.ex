defmodule WishlistsWeb.SharedFolderLive.Show do
  use WishlistsWeb, :live_view
  alias Wishlists.Folders
  alias Wishlists.Accounts
  alias Wishlists.Cards
  alias Wishlists.Accounts.Guardian
  require Logger

  @impl true
  def mount(%{"token" => token}, session, socket) do
    socket = set_locale(socket, session)

    case Folders.get_shared_folder_by_token(token) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Invalid share link")
         |> redirect(to: "/")}

      shared_folder ->
        if shared_folder.share_slug do
          {:ok,
           socket
           |> redirect(to: ~p"/shared/#{shared_folder.share_slug}")}
        else
          handle_shared_folder_mount(shared_folder, session, socket)
        end
    end
  end

  def mount(%{"slug" => slug}, session, socket) do
    Logger.debug("Mounting SharedFolderLive.Show with slug: #{slug}")
    socket = set_locale(socket, session)

    case Folders.get_shared_folder_by_slug(slug) || Folders.get_shared_folder_by_token(slug) do
      nil ->
        Logger.debug("No shared folder found for slug: #{slug}")

        {:ok,
         socket
         |> put_flash(:error, "Invalid share link")
         |> redirect(to: "/")}

      shared_folder ->
        handle_shared_folder_mount(shared_folder, session, socket)
    end
  end

  defp handle_shared_folder_mount(shared_folder, session, socket) do
    Logger.debug("Found shared folder: #{inspect(shared_folder)}")

    locale = session["locale"] || "en"
    Gettext.put_locale(WishlistsWeb.Gettext, locale)

    folder = Folders.get_folder!(shared_folder.folder_id)

    current_user =
      case Guardian.decode_and_verify(session["guardian_default_token"]) do
        {:ok, claims} ->
          {:ok, user} = Guardian.resource_from_claims(claims)
          Wishlists.Repo.preload(user, :account)

        _ ->
          nil
      end

    if current_user && current_user.id == folder.user_id do
      {:ok,
       socket
       |> assign(:locale, locale)
       |> assign(:show_dropdown, false)
       |> redirect(to: ~p"/folders/#{folder.id}")}
    else
      is_following = current_user && Folders.is_following?(current_user.id, folder.id)
      viewer_token = session["viewer_token"]
      guest_viewer = viewer_token && Accounts.get_guest_viewer_by_token(viewer_token)

      cards = Cards.list_folder_cards(folder.id)

      socket =
        socket
        |> assign(:locale, locale)
        |> assign(:shared_folder, shared_folder)
        |> assign(:folder, folder)
        |> assign(:cards, cards)
        |> assign(:guest_viewer, guest_viewer)
        |> assign(:current_user, current_user)
        |> assign(:is_following, is_following)
        |> assign(:show_name_modal, is_nil(current_user) && is_nil(guest_viewer))
        |> assign(:show_auth_modal, false)
        |> assign(:show_suggest_modal, false)
        |> assign(:suggested_card, %Cards.Card{})
        |> assign(:is_suggestion, false)
        |> assign(:show_dropdown, false)

      if current_user && !is_following do
        Folders.follow_folder(current_user.id, folder.id)
      end

      {:ok, socket}
    end
  end

  def handle_event("open_auth_modal", _, socket) do
    {:noreply, assign(socket, show_auth_modal: true)}
  end

  def handle_event("save_viewer_name", %{"guest_viewer" => %{"name" => name}}, socket) do
    case Accounts.create_guest_viewer(%{name: name}) do
      {:ok, guest_viewer} ->
        {:noreply,
         socket
         |> push_event("set-cookie", %{
           key: "_visitor_name",
           value: name,
           max_age: 30 * 24 * 60 * 60
         })
         |> redirect(
           to:
             ~p"/set_viewer_session?token=#{guest_viewer.viewer_token}&return_to=#{socket.assigns.shared_folder.share_slug}"
         )}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Error saving your name")
         |> assign(:show_name_modal, true)}
    end
  end

  def handle_event("logout_guest", _, socket) do
    return_to = ~p"/shared/#{socket.assigns.shared_folder.share_slug}"

    {:noreply,
     socket
     |> push_event("clear-cookie", %{key: "_visitor_name"})
     |> redirect(to: ~p"/clear_viewer_session?return_to=#{return_to}")}
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  def handle_event("login", %{"user" => user_params}, socket) do
    case Accounts.authenticate_user(user_params["email"], user_params["password"]) do
      {:ok, user} ->
        {:noreply,
         socket
         |> redirect(
           to:
             ~p"/auth/set_session?user_id=#{user.id}&return_to=/shared/#{socket.assigns.shared_folder.share_token}"
         )}

      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Invalid email or password"))
         |> assign(:show_name_modal, true)}
    end
  end

  def handle_event("register", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> redirect(
           to:
             ~p"/auth/set_session?user_id=#{user.id}&return_to=/shared/#{socket.assigns.shared_folder.share_token}"
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Registration failed"))
         |> assign(:show_name_modal, true)
         |> assign(:registration_changeset, changeset)}
    end
  end

  def handle_event("reserve_card", %{"card_id" => folder_card_id}, socket) do
    folder_card_id = String.to_integer(folder_card_id)
    folder_card = Cards.get_folder_card!(folder_card_id)

    folder = Wishlists.Repo.preload(socket.assigns.folder, :user)

    if folder_card.card.status != "approved" do
      {:noreply,
       socket
       |> put_flash(:error, gettext("Can't reserve pending or rejected gifts"))}
    else
      reserver_name =
        cond do
          socket.assigns.current_user -> socket.assigns.current_user.email
          socket.assigns.guest_viewer -> socket.assigns.guest_viewer.name
          true -> nil
        end

      attrs =
        cond do
          socket.assigns.current_user ->
            %{
              "reserved_by_user_id" => socket.assigns.current_user.id,
              "reserver_name" => socket.assigns.current_user.email
            }

          socket.assigns.guest_viewer ->
            %{
              "reserved_by_guest_id" => socket.assigns.guest_viewer.id,
              "reserver_name" => socket.assigns.guest_viewer.name
            }

          true ->
            {:noreply, socket}
        end

      case Cards.reserve_card(folder_card_id, attrs) do
        {:ok, _reservation} ->
          Task.start(fn ->
            Wishlists.Notifications.notify_reservation(
              folder,
              folder_card,
              reserver_name
            )
          end)

          cards = Cards.list_folder_cards(folder.id)
          {:noreply, assign(socket, :cards, cards)}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, gettext("Could not reserve card"))}
      end
    end
  end

  def handle_event("unreserve_card", %{"card_id" => card_id}, socket) do
    folder_card_id = String.to_integer(card_id)

    case Cards.unreserve_card(folder_card_id) do
      {:ok, _} ->
        cards = Cards.list_folder_cards(socket.assigns.folder.id)
        {:noreply, assign(socket, :cards, cards)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Could not unreserve card"))}
    end
  end

  def handle_event("suggest_card", _, socket) do
    {:noreply,
     socket
     |> assign(:suggested_card, %Cards.Card{})
     |> assign(:show_suggest_modal, true)
     |> assign(:is_suggestion, true)
     |> assign(:folder, socket.assigns.folder)}
  end

  def handle_event("submit_suggestion", %{"card" => card_params}, socket) do
    folder_id = socket.assigns.folder.id

    suggester_attrs =
      cond do
        socket.assigns.current_user ->
          %{"suggested_by_user_id" => socket.assigns.current_user.id}

        socket.assigns.guest_viewer ->
          %{"suggested_by_guest_id" => socket.assigns.guest_viewer.id}

        true ->
          %{}
      end

    card_params = Map.merge(card_params, suggester_attrs)

    case Cards.suggest_card(folder_id, card_params) do
      {:ok, _card} ->
        {:noreply,
         socket
         |> assign(:show_suggest_modal, false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, suggested_card_changeset: changeset)}
    end
  end

  def handle_event("approve_card", %{"id" => card_id}, socket) do
    card_id = String.to_integer(card_id)

    case Cards.approve_card(card_id) do
      {:ok, _card} ->
        cards = Cards.list_folder_cards(socket.assigns.folder.id)

        {:noreply,
         socket
         |> assign(:cards, cards)}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Failed to approve gift suggestion"))}
    end
  end

  def handle_event("reject_card", %{"id" => card_id}, socket) do
    card_id = String.to_integer(card_id)

    case Cards.reject_card(card_id) do
      {:ok, _card} ->
        cards = Cards.list_folder_cards(socket.assigns.folder.id)

        {:noreply,
         socket
         |> assign(:cards, cards)}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Failed to reject gift suggestion"))}
    end
  end

  @impl true
  def handle_event("toggle_dropdown", _, socket) do
    {:noreply, assign(socket, :show_dropdown, !socket.assigns.show_dropdown)}
  end

  def handle_event("close_dropdown", _, socket) do
    {:noreply, assign(socket, :show_dropdown, false)}
  end

  defp can_unreserve?(reservation, current_user, guest_viewer) do
    cond do
      is_nil(reservation) -> false
      current_user && reservation.reserved_by_user_id == current_user.id -> true
      guest_viewer && reservation.reserved_by_guest_id == guest_viewer.id -> true
      true -> false
    end
  end

  @impl true
  def handle_info({:login_error, message}, socket) do
    {:noreply,
     socket
     |> put_flash(:error, message)
     |> assign(show_auth_modal: true)}
  end

  def handle_info(:close_modal, socket) do
    {:noreply,
     socket
     |> assign(:show_auth_modal, false)
     |> assign(:show_suggest_modal, false)}
  end

  def handle_info({:login_success, _user, token}, socket) do
    {:noreply,
     socket
     |> clear_flash()
     |> redirect(
       to:
         ~p"/auth/set_session?token=#{token}&return_to=/shared/#{socket.assigns.shared_folder.share_token}"
     )}
  end

  def handle_info({:card_suggested, card}, socket) do
    case Cards.assign_card_to_folder(card.id, socket.assigns.folder.id) do
      {:ok, _folder_card} ->
        folder = socket.assigns.folder |> Wishlists.Repo.preload(:user)

        suggester_name =
          cond do
            card.suggested_by_user_id ->
              user = Wishlists.Accounts.get_user!(card.suggested_by_user_id)
              user.email

            card.suggested_by_guest_id ->
              guest = Wishlists.Accounts.get_guest_viewer!(card.suggested_by_guest_id)
              guest.name

            true ->
              gettext("Anonymous")
          end

        Logger.info("Sending suggestion notification for card: #{inspect(card)}")

        Task.start(fn ->
          Wishlists.Email.EmailService.send_suggestion_notification(
            folder,
            %{card: Wishlists.Repo.preload(card, :folder_cards)},
            suggester_name
          )
        end)

        cards = Cards.list_folder_cards(socket.assigns.folder.id)

        {:noreply,
         socket
         |> assign(:cards, cards)
         |> assign(:show_suggest_modal, false)
         |> put_flash(
           :info,
           gettext("Gift suggestion submitted successfully! Waiting for approval.")
         )}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Failed to submit gift suggestion"))}
    end
  end

  def handle_info({:card_created}, socket) do
    cards = Cards.list_folder_cards(socket.assigns.folder.id)

    {:noreply,
     socket
     |> assign(:cards, cards)
     |> assign(:show_suggest_modal, false)}
  end

  defp format_price(price) when is_nil(price) or price <= 0, do: nil

  defp format_price(price) do
    "#{Decimal.to_float(price) |> :erlang.float_to_binary(decimals: 0)} ₽"
  end

  defp set_locale(socket, session) do
    locale = session["locale"] || "en"
    Gettext.put_locale(WishlistsWeb.Gettext, locale)
    assign(socket, :locale, locale)
  end
end
