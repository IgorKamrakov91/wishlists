defmodule WishlistsWeb.NotificationSettingsControllerTest do
  use WishlistsWeb.ConnCase
  require Logger

  describe "email integration" do
    test "unsubscribe link in email works correctly" do
      {:ok, user} =
        Wishlists.Accounts.register_user(%{
          email: "test@example.com",
          password: "password123",
          notification_preferences: %{
            "cleanup_notifications" => true,
            "reservation_notifications" => true
          }
        })

      assert_received {:email, _welcome_email}

      token = Wishlists.Accounts.generate_unsubscribe_token(user)

      initial_user = Wishlists.Accounts.get_user!(user.id)
      assert get_in(initial_user.notification_preferences, ["reservation_notifications"]) == true

      conn =
        build_conn()
        |> get(~p"/notifications/unsubscribe/reservation_notifications/#{token}")

      assert redirected_to(conn) == ~p"/"

      updated_user = Wishlists.Repo.reload!(user)
      assert get_in(updated_user.notification_preferences, ["reservation_notifications"]) == false
    end
  end

  describe "unsubscribe from notifications when authenticated" do
    setup %{conn: conn} do
      {:ok, user} =
        Wishlists.Accounts.register_user(%{
          email: "test@example.com",
          password: "password123",
          notification_preferences: %{
            "cleanup_notifications" => true,
            "reservation_notifications" => true
          }
        })

      assert_received {:email, _}

      conn =
        conn
        |> Map.put(:secret_key_base, WishlistsWeb.Endpoint.config(:secret_key_base))
        |> init_test_session(%{})
        |> Guardian.Plug.sign_in(Wishlists.Accounts.Guardian, user)
        |> assign(:current_user, user)

      %{user: user, conn: conn}
    end

    test "authenticated user can unsubscribe from cleanup notifications", %{
      conn: conn,
      user: user
    } do
      conn = get(conn, ~p"/notifications/settings/cleanup_notifications/unsubscribe")
      assert redirected_to(conn) == ~p"/"

      updated_user = Wishlists.Accounts.get_user!(user.id)
      assert get_in(updated_user.notification_preferences, ["cleanup_notifications"]) == false
      assert get_in(updated_user.notification_preferences, ["reservation_notifications"]) == true
    end

    test "authenticated user can unsubscribe from reservation notifications", %{
      conn: conn,
      user: user
    } do
      conn = get(conn, ~p"/notifications/settings/reservation_notifications/unsubscribe")
      assert redirected_to(conn) == ~p"/"

      updated_user = Wishlists.Accounts.get_user!(user.id)
      assert get_in(updated_user.notification_preferences, ["reservation_notifications"]) == false
      assert get_in(updated_user.notification_preferences, ["cleanup_notifications"]) == true
    end

    test "rejects unsupported notification types without changing preferences", %{
      conn: conn,
      user: user
    } do
      conn = get(conn, ~p"/notifications/settings/marketing_notifications/unsubscribe")
      assert redirected_to(conn) == ~p"/"

      updated_user = Wishlists.Accounts.get_user!(user.id)
      assert get_in(updated_user.notification_preferences, ["cleanup_notifications"]) == true
      assert get_in(updated_user.notification_preferences, ["reservation_notifications"]) == true
    end
  end

  describe "unsubscribe with token" do
    test "rejects unsupported notification types without changing preferences" do
      {:ok, user} =
        Wishlists.Accounts.register_user(%{
          email: "token-test@example.com",
          password: "password123",
          notification_preferences: %{
            "cleanup_notifications" => true,
            "reservation_notifications" => true
          }
        })

      assert_received {:email, _welcome_email}

      token = Wishlists.Accounts.generate_unsubscribe_token(user)

      conn =
        build_conn()
        |> get(~p"/notifications/unsubscribe/marketing_notifications/#{token}")

      assert redirected_to(conn) == ~p"/"

      updated_user = Wishlists.Accounts.get_user!(user.id)
      assert get_in(updated_user.notification_preferences, ["cleanup_notifications"]) == true
      assert get_in(updated_user.notification_preferences, ["reservation_notifications"]) == true
    end
  end
end
