defmodule WishlistsWeb.AuthControllerTest do
  use WishlistsWeb.ConnCase

  setup %{conn: conn} do
    {:ok, user} =
      Wishlists.Accounts.register_user(%{
        "email" => "test@example.com",
        "password" => "password123"
      })

    %{user: user, conn: conn}
  end

  describe "set_session/2" do
    test "sets locale from params", %{conn: conn} do
      token = "test_token"

      conn = get(conn, ~p"/auth/set_session?token=#{token}&locale=ru")

      assert get_session(conn, :locale) == "ru"
      assert redirected_to(conn) == ~p"/dashboard"
    end

    test "defaults to ru locale when none provided", %{conn: conn} do
      token = "test_token"

      conn = get(conn, ~p"/auth/set_session?token=#{token}")

      assert get_session(conn, :locale) == "ru"
      assert redirected_to(conn) == ~p"/dashboard"
    end
  end
end
