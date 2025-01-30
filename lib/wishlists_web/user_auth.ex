defmodule WishlistsWeb.UserAuth do
  use WishlistsWeb, :verified_routes

  # For conn-based functions
  import Plug.Conn, except: [assign: 3]
  import Phoenix.Controller, except: [redirect: 2]

  # For LiveView functions
  import Phoenix.Component
  # Avoid conflict with Phoenix.Component.assign
  import Phoenix.LiveView, except: [assign: 3]

  alias Wishlists.Accounts

  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont,
     assign_new(socket, :current_user, fn ->
       if user_id = session["user_id"] do
         Wishlists.Accounts.get_user!(user_id)
       end
     end)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    if user_id = session["user_id"] do
      {:cont,
       assign_new(socket, :current_user, fn ->
         Wishlists.Accounts.get_user!(user_id)
       end)}
    else
      {:halt,
       socket
       |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
       |> Phoenix.LiveView.redirect(to: "/")}
    end
  end

  def log_in_user(socket, user) do
    token = Phoenix.Token.sign(socket, "user auth", user.id)

    socket
    |> Phoenix.Component.assign(:current_user, user)
    |> Phoenix.LiveView.push_event("user-token", %{token: token})
  end

  def log_out_user(conn) do
    if live_socket_id = get_session(conn, :live_socket_id) do
      WishlistsWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    # Be explicit about which redirect to use
    |> Phoenix.Controller.redirect(to: ~p"/")
  end

  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  defp signed_in_path(_conn), do: ~p"/dashboard"
end
