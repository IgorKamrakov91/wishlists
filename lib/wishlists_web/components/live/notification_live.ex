defmodule WishlistsWeb.NotificationLive do
  use WishlistsWeb, :live_view
  require Logger

  def mount(_params, _session, socket) do
    Logger.info("Mounting NotificationLive")

    if connected?(socket) && socket.assigns[:current_user] do
      user_id = socket.assigns.current_user.id
      Logger.info("Subscribing to notifications for user #{user_id}")

      Phoenix.PubSub.subscribe(
        Wishlists.PubSub,
        "notifications:#{user_id}"
      )
    end

    {:ok, assign_notifications(socket)}
  end

  def handle_info({:new_notification}, socket) do
    Logger.info("Received new notification for user #{socket.assigns.current_user.id}")
    {:noreply, assign_notifications(socket)}
  end

  defp assign_notifications(socket) do
    if socket.assigns[:current_user] do
      notifications =
        Wishlists.Notifications.list_unread_notifications(socket.assigns.current_user.id)

      Logger.info("Found #{length(notifications)} unread notifications")
      assign(socket, :notifications, notifications)
    else
      assign(socket, :notifications, [])
    end
  end
end
