defmodule Wishlists.Email.EmailServiceTest do
  use Wishlists.DataCase
  alias Wishlists.Email.EmailService
  alias Wishlists.Accounts
  alias Wishlists.Folders
  alias Wishlists.Cards

  import Swoosh.TestAssertions

  describe "emails with unsubscribe header" do
    setup do
      # Create user with notification preferences
      {:ok, user} =
        Accounts.register_user(%{
          email: "test@example.com",
          password: "password123",
          notification_preferences: %{
            "cleanup_notifications" => true,
            "reservation_notifications" => true
          }
        })

      # Create folder with future date
      {:ok, folder} =
        Folders.create_folder(%{
          name: "Test Folder",
          event_type: "birthday",
          event_date: Date.add(Date.utc_today(), 10),
          user_id: user.id,
          show_reserver_names: true
        })

      # Create card
      {:ok, card} =
        Cards.create_card(%{
          title: "Test Item",
          description: "Test Description",
          link_url: "http://example.com",
          user_id: user.id
        })

      # Create folder_card and preload associations
      {:ok, folder_card} =
        Cards.assign_card_to_folder(card.id, folder.id)

      folder_card = Repo.preload(folder_card, :card)
      folder = Repo.preload(folder, :user)

      %{
        user: user,
        folder: folder,
        card: card,
        folder_card: folder_card
      }
    end

    test "reservation notification includes unsubscribe header", %{
      user: user,
      folder: folder,
      folder_card: folder_card
    } do
      assert_received {:email, _}

      EmailService.send_reservation_notification(folder, folder_card, "Test Reserver")

      assert_email_sent(fn email ->
        assert email.to == [{user.email, user.email}]
        assert email.subject == "New Reservation in Your Wishlist!"

        {_, unsubscribe_header} =
          Enum.find(email.headers, fn {name, _} -> name == "List-Unsubscribe" end)

        assert unsubscribe_header != nil

        assert String.contains?(
                 unsubscribe_header,
                 "/notifications/unsubscribe/reservation_notifications/"
               )
      end)
    end

    test "cleanup notification includes unsubscribe header", %{
      user: user,
      folder: folder,
      folder_card: folder_card
    } do
      # Skip welcome email
      assert_received {:email, _}

      # Set event_date to yesterday
      yesterday = Date.add(Date.utc_today(), -1)

      {:ok, past_folder} =
        folder
        |> Ecto.Changeset.change(%{event_date: yesterday})
        |> Repo.update()

      past_folder = Repo.preload(past_folder, :user)

      EmailService.send_folder_cleanup_notification(past_folder, [folder_card])

      assert_email_sent(fn email ->
        assert email.to == [{user.email, user.email}]
        assert email.subject == "Your Wishlist Will Be Archived Soon"

        {_, unsubscribe_header} =
          Enum.find(email.headers, fn {name, _} -> name == "List-Unsubscribe" end)

        assert unsubscribe_header != nil

        assert String.contains?(
                 unsubscribe_header,
                 "/notifications/unsubscribe/cleanup_notifications/"
               )
      end)
    end

    test "notifications are not sent when disabled", %{
      user: user,
      folder: folder,
      folder_card: folder_card
    } do
      # Skip welcome email
      assert_received {:email, _}

      # Update user notification preferences
      {:ok, user} =
        Accounts.update_user_notification_preferences(user, %{
          notification_preferences: %{
            "cleanup_notifications" => false,
            "reservation_notifications" => false
          }
        })

      folder = %{folder | user: user}

      assert {:ok, :notifications_disabled} =
               EmailService.send_reservation_notification(folder, folder_card, "Test Reserver")

      assert {:ok, :notifications_disabled} =
               EmailService.send_folder_cleanup_notification(folder, [folder_card])

      refute_received {:email, _}
    end
  end
end
