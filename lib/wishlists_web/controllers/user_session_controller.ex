defmodule WishlistsWeb.UserSessionController do
  use WishlistsWeb, :controller

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Wishlists.Accounts.get_user_by_email(email) do
      conn
      |> put_session(:user_id, user.id)
      |> configure_session(renew: true)
      |> json(%{success: true})
    else
      conn
      |> put_status(:unauthorized)
      |> json(%{success: false})
    end
  end

  def delete(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: ~p"/")
  end
end
