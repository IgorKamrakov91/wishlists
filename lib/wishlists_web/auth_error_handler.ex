defmodule WishlistsWeb.AuthErrorHandler do
  use WishlistsWeb, :controller

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {_type, _reason}, _opts) do
    conn
    |> put_flash(:error, "You must be logged in to access this page")
    |> redirect(to: ~p"/")
  end
end
