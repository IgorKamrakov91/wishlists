defmodule WishlistsWeb.SharedFolderLive.Show do
  use WishlistsWeb, :live_view
  alias Wishlists.Folders
  alias Wishlists.Accounts
  alias Wishlists.Cards
  alias Wishlists.Accounts.Guardian
  require Logger

  def mount(%{"token" => token}, session, socket) do
    Logger.debug("Mounting SharedFolderLive.Show with token: #{token}")

    viewer_name_from_cookie = get_connect_params(socket)["_visitor_name"]

    case Folders.get_shared_folder_by_token(token) do
      nil ->
        Logger.debug("No shared folder found for token: #{token}")

        {:ok,
         socket
         |> put_flash(:error, "Invalid or expired share link")
         |> redirect(to: "/")}

      shared_folder ->
        Logger.debug("Found shared folder: #{inspect(shared_folder)}")

        current_user =
          case Guardian.decode_and_verify(session["guardian_default_token"]) do
            {:ok, claims} ->
              {:ok, user} = Guardian.resource_from_claims(claims)
              user

            _ ->
              nil
          end

        viewer_token = session["viewer_token"]
        guest_viewer = viewer_token && Accounts.get_guest_viewer_by_token(viewer_token)
        Logger.debug("Guest viewer: #{inspect(guest_viewer)}")

        folder = Folders.get_folder!(shared_folder.folder_id)
        cards = Cards.list_folder_cards(folder.id)

        socket =
          socket
          |> assign(:shared_folder, shared_folder)
          |> assign(:folder, folder)
          |> assign(:cards, cards)
          |> assign(:guest_viewer, guest_viewer)
          |> assign(:current_user, current_user)
          |> assign(:show_name_modal, is_nil(current_user) && is_nil(guest_viewer))
          |> assign(:show_auth_modal, false)

        socket =
          if viewer_name_from_cookie && is_nil(current_user) && is_nil(guest_viewer) do
            case Accounts.create_guest_viewer(%{name: viewer_name_from_cookie}) do
              {:ok, new_guest_viewer} ->
                socket
                |> redirect(
                  to:
                    ~p"/set_viewer_session?token=#{new_guest_viewer.viewer_token}&return_to=#{shared_folder.share_token}"
                )

              _ ->
                socket
            end
          else
            socket
          end

        socket =
          assign(
            socket,
            :show_name_modal,
            is_nil(current_user) && is_nil(guest_viewer) && is_nil(viewer_name_from_cookie)
          )

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
             ~p"/set_viewer_session?token=#{guest_viewer.viewer_token}&return_to=#{socket.assigns.shared_folder.share_token}"
         )}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Error saving your name")
         |> assign(:show_name_modal, true)}
    end
  end

  def handle_event("logout_guest", _, socket) do
    {:noreply,
     socket
     |> push_event("clear-cookie", %{key: "_visitor_name"})
     |> redirect(to: ~p"/clear_viewer_session?return_to=/")}
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
         |> put_flash(:error, "Invalid email or password")
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
         |> put_flash(:error, "Registration failed")
         |> assign(:show_name_modal, true)
         |> assign(:registration_changeset, changeset)}
    end
  end

  def handle_info({:login_error, message}, socket) do
    {:noreply,
     socket
     |> put_flash(:error, message)
     |> assign(show_auth_modal: true)}
  end

  def handle_info(:close_modal, socket) do
    {:noreply, assign(socket, show_auth_modal: false)}
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
end
