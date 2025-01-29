defmodule WishlistsWeb.UserAuth do
  use WishlistsWeb, :verified_routes
  import Plug.Conn
  import Phoenix.Controller

  alias Wishlists.Accounts

  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont,
     Phoenix.Component.assign_new(socket, :current_user, fn ->
       if user_id = session["user_id"] do
         Accounts.get_user!(user_id)
       end
     end)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    if user_id = session["user_id"] do
      {:cont,
       Phoenix.Component.assign_new(socket, :current_user, fn ->
         Accounts.get_user!(user_id)
       end)}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/")}
    end
  end

  def log_in_user(conn, user) do
    token = Phoenix.Token.sign(conn, "user auth", user.id)
    user_return_to = get_session(conn, :user_return_to)

    conn
    |> renew_session()
    |> put_session(:user_id, user.id)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
    |> redirect(to: user_return_to || signed_in_path(conn))
  end

  def log_out_user(conn) do
    if live_socket_id = get_session(conn, :live_socket_id) do
      WishlistsWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> redirect(to: ~p"/")
  end

  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  defp signed_in_path(_conn), do: ~p"/dashboard"
end
