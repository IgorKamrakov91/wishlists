defmodule WishlistsWeb.PageControllerTest do
  use WishlistsWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)

    assert response =~ "Wishlists Manager"
    assert response =~ "Create and manage your wishlists effortlessly"
    assert response =~ "Get Started"
  end
end
