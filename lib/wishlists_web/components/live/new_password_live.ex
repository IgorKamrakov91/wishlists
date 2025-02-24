defmodule WishlistsWeb.NewPasswordLive do
  use WishlistsWeb, :live_view
  alias Wishlists.Accounts

  def mount(%{"token" => token}, _session, socket) do
    {:ok,
     socket
     |> assign(:token, token)
     |> assign(:password, "")
     |> assign(:error_message, nil)
     |> assign(:success, false)
     |> assign(:locale, "en")}
  end

  def handle_event("reset_password", %{"password" => password}, socket) do
    case Accounts.reset_password(socket.assigns.token, password) do
      {:ok, _user} ->
        {:noreply, assign(socket, success: true)}

      {:error, :invalid_token} ->
        {:noreply, assign(socket, error_message: "Invalid or expired reset link")}

      {:error, :token_expired} ->
        {:noreply, assign(socket, error_message: "Reset link has expired")}

      {:error, %Ecto.Changeset{} = changeset} ->
        error_message = traverse_errors(changeset)
        {:noreply, assign(socket, error_message: error_message)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto mt-10 p-6 bg-white rounded-lg shadow-lg">
      <%= if @success do %>
        <div class="text-center">
          <h2 class="text-2xl font-bold mb-4">Password Reset Successfully</h2>
          <p class="text-gray-600 mb-4">You can now sign in with your new password.</p>
          <.link
            navigate={~p"/"}
            class="inline-block bg-indigo-600 text-white py-2 px-4 rounded hover:bg-indigo-700"
          >
            Go to Sign In
          </.link>
        </div>
      <% else %>
        <h2 class="text-2xl font-bold mb-4">Set New Password</h2>

        <%= if @error_message do %>
          <div class="mb-4 p-3 bg-red-100 text-red-700 rounded">
            {@error_message}
          </div>
        <% end %>

        <form phx-submit="reset_password">
          <div class="mb-4">
            <label class="block text-gray-700 mb-2">New Password</label>
            <input
              type="password"
              name="password"
              value={@password}
              required
              class="w-full p-2 border rounded"
              placeholder="Enter new password"
              minlength="8"
            />
          </div>
          <button
            type="submit"
            class="w-full bg-indigo-600 text-white py-2 rounded hover:bg-indigo-700"
          >
            Set New Password
          </button>
        </form>
      <% end %>
    </div>
    """
  end

  defp traverse_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {_key, value} -> value end)
    |> List.first()
  end
end
