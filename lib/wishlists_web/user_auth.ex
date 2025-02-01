defmodule WishlistsWeb.UserAuth do
  use WishlistsWeb, :verified_routes
  import Phoenix.Component
  import Phoenix.LiveView
  alias Wishlists.Accounts.Guardian

  def on_mount(:mount_current_user, _params, session, socket) do
    case Guardian.decode_and_verify(session["guardian_default_token"]) do
      {:ok, claims} ->
        case Guardian.resource_from_claims(claims) do
          {:ok, user} ->
            {:cont, assign(socket, current_user: user)}

          {:error, _reason} ->
            {:cont, assign(socket, current_user: nil)}
        end

      _ ->
        {:cont, assign(socket, current_user: nil)}
    end
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    case Guardian.decode_and_verify(session["guardian_default_token"]) do
      {:ok, claims} ->
        case Guardian.resource_from_claims(claims) do
          {:ok, user} ->
            {:cont, assign(socket, current_user: user)}

          {:error, _reason} ->
            {:halt,
             socket
             |> put_flash(:error, "You must log in to access this page.")
             |> redirect(to: ~p"/")}
        end

      _ ->
        {:halt,
         socket
         |> put_flash(:error, "You must log in to access this page.")
         |> redirect(to: ~p"/")}
    end
  end
end
