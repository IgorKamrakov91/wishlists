defmodule WishlistsWeb.AuthController do
  use WishlistsWeb, :controller

  def set_session(conn, %{"token" => token}) do
    conn
    |> put_session("guardian_default_token", token)
    |> configure_session(renew: true)
    |> redirect(to: ~p"/dashboard")
  end

  def sign_out(conn, _params) do
    conn
    |> clear_session()
    |> configure_session(drop: true)
    |> redirect(to: ~p"/")
  end
end
