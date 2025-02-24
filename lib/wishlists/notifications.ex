defmodule Wishlists.Notifications do
  import Ecto.Query
  alias Wishlists.Repo
  alias Wishlists.Notifications.Notification

  def create_notification(attrs \\ %{}) do
    %Notification{}
    |> Notification.changeset(attrs)
    |> Repo.insert()
  end

  def list_unread_notifications(user_id) do
    Notification
    |> where([n], n.user_id == ^user_id and is_nil(n.read_at))
    |> order_by([n], desc: n.inserted_at)
    |> Repo.all()
  end

  def mark_as_read(notification_id) do
    from(n in Notification, where: n.id == ^notification_id)
    |> Repo.update_all(set: [read_at: DateTime.utc_now()])
  end

  def broadcast_notification(user_id) do
    Phoenix.PubSub.broadcast!(
      Wishlists.PubSub,
      "user_notifications:#{user_id}",
      {:new_notification}
    )
  end

  def notify_reservation(folder, folder_card, reserver_name) do
    folder =
      if Ecto.assoc_loaded?(folder.user) do
        folder
      else
        Repo.preload(folder, :user)
      end

    title = String.slice(folder_card.card.title, 0, 50)
    title = if String.length(folder_card.card.title) > 50, do: title <> "...", else: title

    data = %{
      folder_id: folder.id,
      folder_card_id: folder_card.id,
      card_id: folder_card.card_id,
      reserver_name: reserver_name,
      card_title: title,
      folder_name: folder.name
    }

    notification_attrs = %{
      user_id: folder.user_id,
      type: "card_reserved",
      title: "Hooray!",
      message: "#{title} in #{folder.name} has been reserved",
      data: data
    }

    with {:ok, notification} <- create_notification(notification_attrs) do
      Wishlists.Email.EmailService.send_reservation_notification(
        folder,
        folder_card,
        reserver_name
      )
      |> Wishlists.Email.EmailService.handle_delivery()

      broadcast_notification(folder.user_id)
      {:ok, notification}
    end
  end
end
