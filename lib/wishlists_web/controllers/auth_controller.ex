defmodule WishlistsWeb.AuthController do
  use WishlistsWeb, :controller

  def set_session(conn, %{"token" => token, "locale" => locale}) do
    conn
    |> put_session(:guardian_default_token, token)
    |> put_session(:locale, locale)
    |> redirect(to: ~p"/dashboard")
  end

  def set_session(conn, %{"token" => token}) do
    set_session(conn, %{"token" => token, "locale" => "ru"})
  end

  def sign_out(conn, _params) do
    conn
    |> clear_session()
    |> configure_session(drop: true)
    |> redirect(to: ~p"/")
  end
end
