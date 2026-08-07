defmodule WishlistsWeb.PageLiveTest do
  use WishlistsWeb.ConnCase
  import Phoenix.LiveViewTest

  setup %{conn: conn} do
    {:ok, user} =
      Wishlists.Accounts.register_user(%{
        email: "test@example.com",
        password: "password123"
      })

    %{user: user, conn: conn}
  end

  describe "locale handling" do
    test "updates user locale on successful login with URL locale", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, "/?locale=ru")

      # Wait for the view to be fully mounted and initialized
      :timer.sleep(100)

      send(view.pid, {:login_success, user, "test_token"})

      # Wait for the update to complete
      :timer.sleep(100)

      updated_user = Wishlists.Accounts.get_user!(user.id)
      assert updated_user.locale == "ru"
      assert_redirect(view, "/auth/set_session?token=test_token&locale=ru")
    end

    test "uses default locale when no URL locale present", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, "/")

      send(view.pid, {:login_success, user, "test_token"})

      updated_user = Wishlists.Accounts.get_user!(user.id)
      assert updated_user.locale == "en"

      assert_redirect(view, "/auth/set_session?token=test_token&locale=en")
    end

    test "ignores unsupported session locales", %{conn: conn} do
      conn = init_test_session(conn, %{locale: "de"})

      {:ok, _view, html} = live(conn, "/")

      assert html =~ "Wishlists Manager"
    end

    test "handles locale switch", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      assert render_click(view, "switch_locale", %{"locale" => "ru"}) =~ "RU"
      assert_patched(view, "/?locale=ru")
    end
  end
end
