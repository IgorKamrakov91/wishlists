defmodule WishlistsWeb.NotificationComponent do
  use WishlistsWeb, :live_component
  require Logger

  def update(assigns, socket) do
    if connected?(socket) && assigns[:current_user] do
      topic = "user_notifications:#{assigns.current_user.id}"

      if !socket.assigns[:subscribed_to_notifications] do
        Logger.info("Subscribing to #{topic}")
        Phoenix.PubSub.subscribe(Wishlists.PubSub, topic)
      end
    end

    socket =
      socket
      |> assign(assigns)
      |> assign(:subscribed_to_notifications, true)
      |> assign(:notifications, list_notifications(assigns[:current_user]))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="fixed top-4 right-4 z-50 w-96">
      <%= for notification <- @notifications do %>
        <div class="mb-4 bg-white rounded-lg shadow-lg p-6 animate-slide-in">
          <div class="flex items-start space-x-4">
            <div class="flex-shrink-0">
              <div class="bg-purple-100 rounded-full p-2">
                <.icon name="hero-bell" class="h-6 w-6 text-purple-600" />
              </div>
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-gray-900 mb-1">
                {translate_notification_title(notification.type)}
              </p>
              <p class="text-sm text-gray-500 break-words">
                {translate_notification_message(notification)}
              </p>
              <p class="text-xs text-gray-400 mt-1">
                {format_time(notification.inserted_at)}
              </p>
            </div>
            <div class="flex-shrink-0">
              <button
                phx-click="mark_as_read"
                phx-value-id={notification.id}
                phx-target={@myself}
                class="text-gray-400 hover:text-gray-500 focus:outline-none"
                title={gettext("Mark as read")}
              >
                <.icon name="hero-x-mark" class="h-5 w-5" />
              </button>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_info({:new_notification}, socket) do
    Logger.info("NotificationComponent received new notification")
    notifications = list_notifications(socket.assigns.current_user)
    {:noreply, assign(socket, :notifications, notifications)}
  end

  def handle_event("mark_as_read", %{"id" => id}, socket) do
    Wishlists.Notifications.mark_as_read(id)
    notifications = list_notifications(socket.assigns.current_user)
    {:noreply, assign(socket, :notifications, notifications)}
  end

  defp list_notifications(user) do
    if user do
      Wishlists.Notifications.list_unread_notifications(user.id)
    else
      []
    end
  end

  defp format_time(datetime) do
    Calendar.strftime(datetime, "%H:%M")
  end

  defp translate_notification_title("card_reserved"), do: gettext("Hooray!")
  defp translate_notification_title(_), do: gettext("Notification")

  defp translate_notification_message(%{type: "card_reserved"} = notification) do
    gettext("WISH RESERVED! \"%{title}\" in %{folder_name}",
      title: notification.data["card_title"],
      folder_name: notification.data["folder_name"]
    )
  end

  defp translate_notification_message(_notification), do: gettext("New notification")
end
