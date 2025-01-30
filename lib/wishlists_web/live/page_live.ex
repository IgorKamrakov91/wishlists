defmodule WishlistsWeb.PageLive do
  use WishlistsWeb, :live_view
  alias Wishlists.Accounts.Guardian

  on_mount {WishlistsWeb.UserAuth, :mount_current_user}

  def mount(_params, session, socket) do
    case Guardian.decode_and_verify(session["guardian_default_token"]) do
      {:ok, _claims} ->
        {:ok, push_navigate(socket, to: "/dashboard")}

      _ ->
        {:ok, assign(socket, show_auth_modal: false)}
    end
  end

  def handle_info({:login_success, user, token}, socket) do
    {:noreply,
     socket
     |> clear_flash()
     |> redirect(to: ~p"/auth/set_session?token=#{token}")}
  end

  def handle_info(:close_modal, socket) do
    {:noreply, assign(socket, show_auth_modal: false)}
  end

  def handle_event("open_auth_modal", _, socket) do
    {:noreply, assign(socket, show_auth_modal: true)}
  end
end
