defmodule WishlistsWeb.ViewerSessionController do
  use WishlistsWeb, :controller

  def set_session(conn, %{"token" => viewer_token, "return_to" => share_token}) do
    conn
    |> put_session(:viewer_token, viewer_token)
    |> redirect(to: ~p"/shared/#{share_token}")
  end

  def clear(conn, %{"return_to" => return_to}) do
    conn
    |> delete_session(:viewer_token)
    |> redirect(to: return_to)
  end
end
