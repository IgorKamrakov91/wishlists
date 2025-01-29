defmodule WishlistsWeb.PageController do
  use WishlistsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
