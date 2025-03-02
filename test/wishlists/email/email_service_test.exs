defmodule Wishlists.Email.EmailServiceTest do
  use Wishlists.DataCase
  alias Wishlists.Email.EmailService
  alias Wishlists.Accounts
  alias Wishlists.Folders
  alias Wishlists.Cards

  import Swoosh.TestAssertions

  setup do
    {:ok, user} =
      Accounts.register_user(%{
        email: "test@example.com",
        password: "password123",
        notification_preferences: %{
          "cleanup_notifications" => true,
          "reservation_notifications" => true
        },
        locale: "en"
      })

    {:ok, folder} =
      Folders.create_folder(%{
        name: "Test Folder",
        event_type: "birthday",
        event_date: Date.add(Date.utc_today(), 10),
        user_id: user.id,
        show_reserver_names: true
      })

    {:ok, card} =
      Cards.create_card(%{
        title: "Test Item",
        description: "Test Description",
        link_url: "http://example.com",
        user_id: user.id
      })

    {:ok, folder_card} = Cards.assign_card_to_folder(card.id, folder.id)
    folder_card = Repo.preload(folder_card, :card)
    folder = Repo.preload(folder, :user)

    %{
      user: user,
      folder: folder,
      card: card,
      folder_card: folder_card
    }
  end

  test "welcome email", %{user: user} do
    assert_receive {:email, _}

    EmailService.send_welcome_email(user)

    assert_email_sent(fn email ->
      assert email.to == [{user.email, user.email}]
      assert email.from == {"Wishlists", "notifications@hochu-hochu.com"}
      assert email.subject == "Welcome to Wishlists!"
    end)
  end

  test "reset password email", %{user: user} do
    assert_receive {:email, _}

    user = %{user | reset_password_token: "test-token"}
    EmailService.send_reset_password_email(user)

    assert_email_sent(fn email ->
      assert email.to == [{user.email, user.email}]
      assert email.subject == "Reset Your Password"
      assert email.html_body =~ "test-token"
    end)
  end

  test "reservation notification with visible reserver name", %{
    folder: folder,
    folder_card: folder_card
  } do
    assert_receive {:email, _}

    EmailService.send_reservation_notification(folder, folder_card, "John Doe")

    assert_email_sent(fn email ->
      assert email.to == [{folder.user.email, folder.user.email}]
      assert email.subject == "New Reservation in Your Wishlist!"
      assert email.html_body =~ "John Doe"
    end)
  end

  test "reservation notification with hidden reserver name", %{
    folder: folder,
    folder_card: folder_card
  } do
    assert_receive {:email, _}

    folder = %{folder | show_reserver_names: false}
    EmailService.send_reservation_notification(folder, folder_card, "John Doe")

    assert_email_sent(fn email ->
      refute email.html_body =~ "John Doe"
      assert email.html_body =~ "Someone has reserved"
    end)
  end

  test "cleanup notification", %{folder: folder, folder_card: folder_card} do
    assert_receive {:email, _}

    yesterday = Date.add(Date.utc_today(), -1)
    folder = %{folder | event_date: yesterday}

    EmailService.send_folder_cleanup_notification(folder, [folder_card])

    assert_email_sent(fn email ->
      assert email.to == [{folder.user.email, folder.user.email}]
      assert email.subject == "Your Wishlist Will Be Archived Soon"
      assert email.html_body =~ folder.name
    end)
  end

  test "prevents duplicate cleanup notifications", %{folder: folder, folder_card: folder_card} do
    assert_receive {:email, _}

    yesterday = Date.add(Date.utc_today(), -1)
    folder = %{folder | event_date: yesterday}

    assert {:ok, _} = EmailService.send_folder_cleanup_notification(folder, [folder_card])

    assert {:ok, :already_notified} =
             EmailService.send_folder_cleanup_notification(folder, [folder_card])
  end
end
