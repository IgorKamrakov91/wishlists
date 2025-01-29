defmodule WishlistsWeb.HelloController do
  use WishlistsWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end
end
