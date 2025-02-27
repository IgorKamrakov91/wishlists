defmodule WishlistsWeb.ViewerSessionController do
  use WishlistsWeb, :controller

  def set_session(conn, %{"token" => token, "return_to" => return_to}) do
    conn
    |> put_session(:viewer_token, token)
    |> redirect(to: ~p"/shared/#{return_to}")
  end

  def clear_session(conn, %{"return_to" => return_to}) do
    conn
    |> clear_session()
    |> redirect(to: return_to)
  end
end
