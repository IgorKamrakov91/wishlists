defmodule WishlistsWeb.PageLive do
  use WishlistsWeb, :live_view
  on_mount {WishlistsWeb.UserAuth, :mount_current_user}

  def mount(_params, session, socket) do
    if connected?(socket) && session["user_id"] do
      {:ok, push_navigate(socket, to: "/dashboard")}
    else
      {:ok, assign(socket, show_auth_modal: false)}
    end
  end

  def handle_info({:login_user, user}, socket) do
    {:noreply,
     socket
     |> assign(:current_user, user)
     |> assign(:show_auth_modal, false)
     |> put_flash(:info, "Welcome back!")
     |> push_navigate(to: "/dashboard")}
  end

  def handle_event("open_auth_modal", _, socket) do
    {:noreply, assign(socket, show_auth_modal: true)}
  end

  def handle_info(:close_modal, socket) do
    {:noreply, assign(socket, show_auth_modal: false)}
  end
end
