defmodule WishlistsWeb.ResetPasswordLive do
  use WishlistsWeb, :live_view
  alias Wishlists.Accounts

  on_mount({WishlistsWeb.UserAuth, :mount_current_user})

  def mount(%{"token" => token}, _session, socket) do
    {:ok,
     socket
     |> assign(:token, token)
     |> assign(:page, :reset)
     |> assign(:password, "")
     |> assign(:submitted, false)
     |> assign(:error_message, nil)}
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, :request)
     |> assign(:email, "")
     |> assign(:submitted, false)
     |> assign(:error_message, nil)}
  end

  def handle_event("request_reset", %{"email" => email}, socket) do
    case Accounts.generate_reset_password_token(email) do
      {:ok, _user} ->
        {:noreply, assign(socket, submitted: true)}

      {:error, :not_found} ->
        {:noreply, assign(socket, error_message: "Email not found")}

      {:error, _} ->
        {:noreply, assign(socket, error_message: "Something went wrong")}
    end
  end

  def handle_event("reset_password", %{"password" => password}, socket) do
    case Accounts.reset_password(socket.assigns.token, password) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Password reset successfully!")
         |> redirect(to: ~p"/")}

      {:error, :invalid_token} ->
        {:noreply, assign(socket, error_message: "Invalid or expired token")}

      {:error, :token_expired} ->
        {:noreply, assign(socket, error_message: "Reset token has expired")}

      {:error, _} ->
        {:noreply, assign(socket, error_message: "Could not reset password")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto mt-10 p-6 bg-white rounded-lg shadow-lg">
      <%= if @page == :request do %>
        <%= if @submitted do %>
          <div class="text-center">
            <h2 class="text-2xl font-bold mb-4">Check Your Email</h2>
            <p class="text-gray-600">
              If an account exists for this email, we've sent instructions to reset your password.
            </p>
          </div>
        <% else %>
          <h2 class="text-2xl font-bold mb-4">Reset Password</h2>

          <%= if @error_message do %>
            <div class="mb-4 p-3 bg-red-100 text-red-700 rounded">
              {@error_message}
            </div>
          <% end %>

          <form phx-submit="request_reset">
            <div class="mb-4">
              <label class="block text-gray-700 mb-2">Email</label>
              <input
                type="email"
                name="email"
                value={@email}
                required
                class="w-full p-2 border rounded"
                placeholder="Enter your email"
              />
            </div>
            <button
              type="submit"
              class="w-full bg-indigo-600 text-white py-2 rounded hover:bg-indigo-700"
            >
              Send Reset Instructions
            </button>
          </form>
        <% end %>
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
              minlength="6"
            />
          </div>
          <button
            type="submit"
            class="w-full bg-indigo-600 text-white py-2 rounded hover:bg-indigo-700"
          >
            Reset Password
          </button>
        </form>
      <% end %>
    </div>
    """
  end
end
