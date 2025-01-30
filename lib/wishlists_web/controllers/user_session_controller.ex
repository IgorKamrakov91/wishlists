defmodule WishlistsWeb.UserSessionController do
  use WishlistsWeb, :controller

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    case Wishlists.Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> configure_session(renew: true)
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: ~p"/dashboard")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Invalid email or password")
        |> redirect(to: ~p"/")
    end
  end

  def delete(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: ~p"/")
  end
end
