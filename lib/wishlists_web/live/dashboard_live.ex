defmodule WishlistsWeb.DashboardLive do
  use WishlistsWeb, :live_view
  alias Wishlists.Accounts.Guardian

  on_mount {WishlistsWeb.UserAuth, :ensure_authenticated}

  def mount(_params, session, socket) do
    case Guardian.decode_and_verify(session["guardian_default_token"]) do
      {:ok, claims} ->
        {:ok, user} = Guardian.resource_from_claims(claims)
        {:ok, assign(socket, current_user: user)}

      _ ->
        {:ok,
         socket
         |> put_flash(:error, "You must log in to access this page.")
         |> redirect(to: ~p"/")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-100">
      <header class="bg-white shadow">
        <div class="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8 flex justify-between items-center">
          <h1 class="text-3xl font-bold text-gray-900">
            Welcome, {@current_user.email}!
          </h1>

          <.link
            href={~p"/auth/sign_out"}
            method="delete"
            class="bg-red-500 hover:bg-red-700 text-white font-bold py-2 px-4 rounded"
          >
            Logout
          </.link>
        </div>
      </header>

      <main class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <!-- Your dashboard content -->
        <div class="px-4 py-6 sm:px-0">
          <div class="border-4 border-dashed border-gray-200 rounded-lg h-96 flex items-center justify-center">
            <p class="text-gray-500 text-xl">Your dashboard content will go here</p>
          </div>
        </div>
      </main>
    </div>
    """
  end
end
