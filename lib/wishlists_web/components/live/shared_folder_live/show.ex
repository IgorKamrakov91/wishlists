defmodule WishlistsWeb.SharedFolderLive.Show do
  use WishlistsWeb, :live_view
  alias Wishlists.Folders
  alias Wishlists.Accounts
  require Logger

  def mount(%{"token" => token}, session, socket) do
    Logger.debug("Mounting SharedFolderLive.Show with token: #{token}")

    case Folders.get_shared_folder_by_token(token) do
      nil ->
        Logger.debug("No shared folder found for token: #{token}")

        {:ok,
         socket
         |> put_flash(:error, "Invalid or expired share link")
         |> redirect(to: "/")}

      shared_folder ->
        Logger.debug("Found shared folder: #{inspect(shared_folder)}")
        viewer_token = session["viewer_token"]
        guest_viewer = viewer_token && Accounts.get_guest_viewer_by_token(viewer_token)
        Logger.debug("Guest viewer: #{inspect(guest_viewer)}")

        socket =
          socket
          |> assign(:shared_folder, shared_folder)
          |> assign(:folder, Folders.get_folder!(shared_folder.folder_id))
          |> assign(:guest_viewer, guest_viewer)
          |> assign(:show_name_modal, is_nil(guest_viewer))

        {:ok, socket}
    end
  end

  def handle_event("save_viewer_name", %{"guest_viewer" => %{"name" => name}}, socket) do
    case Accounts.create_guest_viewer(%{name: name}) do
      {:ok, guest_viewer} ->
        {:noreply,
         socket
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
end
