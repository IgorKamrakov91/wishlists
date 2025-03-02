defmodule Wishlists.Email.EmailService do
  alias Wishlists.Mailer
  alias Wishlists.Email.EmailTemplates
  import Swoosh.Email
  require Logger

  def send_welcome_email(user) do
    Gettext.with_locale(user.locale || "en", fn ->
      user
      |> EmailTemplates.welcome_email()
      |> deliver()
    end)
  end

  def send_reset_password_email(user) do
    Gettext.with_locale(user.locale || "en", fn ->
      user
      |> EmailTemplates.reset_password_email()
      |> deliver()
    end)
  end

  def send_reservation_notification(folder, folder_card, reserver_name) do
    folder = Wishlists.Repo.preload(folder, :user)

    if get_in(folder.user.notification_preferences, ["reservation_notifications"]) do
      Gettext.with_locale(folder.user.locale || "en", fn ->
        folder
        |> EmailTemplates.reservation_notification(folder_card, reserver_name)
        |> add_unsubscribe_header("reservation_notifications")
        |> deliver()
      end)
    else
      {:ok, :notifications_disabled}
    end
  end

  def send_folder_cleanup_notification(folder, folder_cards) do
    folder = Wishlists.Repo.preload(folder, :user)

    with true <- get_in(folder.user.notification_preferences, ["cleanup_notifications"]),
         false <- already_notified?(folder) do
      Gettext.with_locale(folder.user.locale || "en", fn ->
        folder.user
        |> EmailTemplates.folder_cleanup_notification(folder, folder_cards)
        |> add_unsubscribe_header("cleanup_notifications")
        |> deliver()
        |> mark_as_notified(folder)
      end)
    else
      false -> {:ok, :notifications_disabled}
      true -> {:ok, :already_notified}
    end
  end

  def handle_delivery({:ok, _result} = ok), do: ok

  def handle_delivery({:error, reason} = error) do
    Logger.error("Failed to deliver email: #{inspect(reason)}")
    error
  end

  defp add_unsubscribe_header(email, notification_type) do
    user = email.to |> List.first() |> elem(0)

    case Wishlists.Accounts.get_user_by_email(user) do
      nil ->
        email

      user ->
        token = Wishlists.Accounts.generate_unsubscribe_token(user)

        unsubscribe_url =
          "#{WishlistsWeb.Endpoint.url()}/notifications/unsubscribe/#{notification_type}/#{token}"

        header(email, "List-Unsubscribe", "<#{unsubscribe_url}>")
    end
  end

  defp already_notified?(folder) do
    Wishlists.Cache.get("folder_notification:#{folder.id}") != nil
  end

  defp mark_as_notified(result, folder) do
    case result do
      {:ok, _} ->
        Wishlists.Cache.put("folder_notification:#{folder.id}", true, ttl: :timer.hours(24))
        result

      error ->
        error
    end
  end

  defp deliver(email) do
    try do
      Mailer.deliver(email)
    rescue
      error ->
        Logger.error("Failed to deliver email: #{inspect(error)}")
        {:error, error}
    end
  end
end
