defmodule Wishlists.Email.EmailService do
  alias Wishlists.Mailer
  alias Wishlists.Email.EmailTemplates
  require Logger

  def send_welcome_email(user) do
    user
    |> EmailTemplates.welcome_email()
    |> deliver()
  end

  def send_reset_password_email(user) do
    user
    |> EmailTemplates.reset_password_email()
    |> deliver()
  end

  def send_reservation_notification(folder, folder_card, reserver_name) do
    folder
    |> EmailTemplates.reservation_notification(folder_card, reserver_name)
    |> deliver()
  end

  def send_folder_cleanup_notification(folder, folder_cards) do
    folder =
      if Ecto.assoc_loaded?(folder.user) do
        folder
      else
        Wishlists.Repo.preload(folder, :user)
      end

    folder.user
    |> EmailTemplates.folder_cleanup_notification(folder, folder_cards)
    |> deliver()
  end

  def handle_delivery({:ok, _result} = ok), do: ok

  def handle_delivery({:error, reason} = error) do
    Logger.error("Failed to deliver email: #{inspect(reason)}")
    error
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
