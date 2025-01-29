defmodule WishlistsWeb.PageLive do
  use WishlistsWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, show_auth_modal: false)}
  end

  def handle_event("open_auth_modal", _, socket) do
    {:noreply, assign(socket, show_auth_modal: true)}
  end

  def handle_info(:close_modal, socket) do
    {:noreply, assign(socket, show_auth_modal: false)}
  end
end
