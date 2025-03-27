defmodule Wishlists.Email.EmailServiceTest do
  use Wishlists.DataCase
  use WishlistsWeb, :verified_routes
  use Gettext, backend: WishlistsWeb.Gettext

  alias Wishlists.Email.EmailService
  alias Wishlists.Accounts
  alias Wishlists.Folders
  alias Wishlists.Cards

  import Swoosh.TestAssertions

  setup do
    {:ok, user} =
      Accounts.register_user(%{
        "email" => "test@example.com",
        "password" => "password123",
        "notification_preferences" => %{
          "cleanup_notifications" => true,
          "reservation_notifications" => true
        },
        "locale" => "ru"
      })

    {:ok, folder} =
      Folders.create_folder(%{
        "name" => "Test Folder",
        "event_type" => "birthday",
        "event_date" => Date.add(Date.utc_today(), 10),
        "user_id" => user.id,
        "show_reserver_names" => true
      })

    {:ok, card} =
      Cards.create_card(%{
        "title" => "Test Item",
        "description" => "Test Description",
        "link_url" => "http://example.com",
        "user_id" => user.id
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
      assert email.subject == gettext("Welcome to Wishlists!")
    end)
  end

  test "reset password email", %{user: user} do
    assert_receive {:email, _}

    user = %{user | reset_password_token: "test-token"}
    EmailService.send_reset_password_email(user)

    assert_email_sent(fn email ->
      assert email.to == [{user.email, user.email}]
      assert email.subject == gettext("Reset Your Password")
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
      assert email.subject == gettext("New Reservation in Your Wishlist!")
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
      assert email.html_body =~ "Кто-то зарезервировал"
    end)
  end

  test "cleanup notification", %{folder: folder, folder_card: folder_card} do
    assert_receive {:email, _}

    yesterday = Date.add(Date.utc_today(), -1)
    folder = %{folder | event_date: yesterday}

    EmailService.send_folder_cleanup_notification(folder, [folder_card])

    assert_email_sent(fn email ->
      assert email.to == [{folder.user.email, folder.user.email}]
      assert email.subject == gettext("Your Wishlist Will Be Archived Soon")
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

  test "suggestion notification", %{folder: folder, folder_card: folder_card} do
    assert_receive {:email, _}

    EmailService.send_suggestion_notification(folder, folder_card, "Jane Doe")

    assert_email_sent(fn email ->
      assert email.to == [{folder.user.email, folder.user.email}]
      assert email.subject == gettext("New Gift Suggestion in Your Wishlist!")
      assert email.html_body =~ "Jane Doe"
      assert email.html_body =~ folder_card.card.title
      assert email.html_body =~ ~p"/folders/#{folder.id}"
    end)
  end

  test "suggestion notification includes price when available", %{
    folder: folder,
    folder_card: folder_card
  } do
    assert_receive {:email, _}

    folder_card = put_in(folder_card.card.price, Decimal.new("99.99"))

    EmailService.send_suggestion_notification(folder, folder_card, "Jane Doe")

    assert_email_sent(fn email ->
      assert email.html_body =~ "99.99"
    end)
  end

  test "suggestion notification includes link when available", %{
    folder: folder,
    folder_card: folder_card
  } do
    assert_receive {:email, _}

    folder_card = put_in(folder_card.card.link_url, "https://example.com")

    EmailService.send_suggestion_notification(folder, folder_card, "Jane Doe")

    assert_email_sent(fn email ->
      assert email.html_body =~ "https://example.com"
    end)
  end

  test "suggestion notification respects user locale", %{folder: folder, folder_card: folder_card} do
    assert_receive {:email, _}

    folder = put_in(folder.user.locale, "ru")

    EmailService.send_suggestion_notification(folder, folder_card, "Jane Doe")

    assert_email_sent(fn email ->
      assert email.subject == "Новое предложение подарка в вашем списке желаний!"
    end)
  end

  test "suggestion notification includes unsubscribe link", %{
    folder: folder,
    folder_card: folder_card
  } do
    assert_receive {:email, _}

    EmailService.send_suggestion_notification(folder, folder_card, "Jane Doe")

    assert_email_sent(fn email ->
      assert email.headers["List-Unsubscribe"]
      assert email.html_body =~ gettext("unsubscribe")
      assert email.html_body =~ "/notifications/unsubscribe/suggestion_notifications/"
    end)
  end
end
