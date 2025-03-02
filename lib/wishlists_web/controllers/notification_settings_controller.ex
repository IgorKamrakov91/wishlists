defmodule WishlistsWeb.NotificationSettingsController do
  use WishlistsWeb, :controller
  alias Wishlists.Accounts

  # Для аутентифицированных пользователей
  def unsubscribe(conn, %{"type" => notification_type}) do
    user = conn.assigns.current_user
    handle_unsubscribe(conn, user, notification_type)
  end

  # Для отписки по токену из email
  def unsubscribe_with_token(conn, %{"type" => notification_type, "token" => token}) do
    case Accounts.verify_unsubscribe_token(token) do
      {:ok, user} ->
        handle_unsubscribe(conn, user, notification_type)

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Invalid or expired unsubscribe link")
        |> redirect(to: ~p"/")
    end
  end

  defp handle_unsubscribe(conn, user, notification_type)
       when notification_type in ["cleanup_notifications", "reservation_notifications"] do
    current_preferences = user.notification_preferences
    updated_preferences = Map.put(current_preferences, notification_type, false)

    case Accounts.update_user_notification_preferences(user, %{
           notification_preferences: updated_preferences
         }) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Successfully unsubscribed from #{notification_type}")
        |> redirect(to: ~p"/")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to update notification preferences")
        |> redirect(to: ~p"/")
    end
  end

  defp handle_unsubscribe(conn, _user, _notification_type) do
    conn
    |> put_flash(:error, "Invalid notification type")
    |> redirect(to: ~p"/")
  end
end
