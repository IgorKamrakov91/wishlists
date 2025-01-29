defmodule WishlistsWeb.AuthComponent do
  use WishlistsWeb, :live_component

  def mount(socket) do
    {:ok, assign(socket, form: to_form(%{}, as: :user), view: :sign_in)}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-black bg-opacity-50 transition-opacity z-50">
      <div class="fixed inset-0 z-50 overflow-y-auto">
        <div class="flex min-h-full items-center justify-center p-4">
          <div class="relative bg-white w-full max-w-md rounded-xl shadow-2xl transform transition-all">
            <!-- Decorative elements -->
            <div class="absolute -top-4 -right-4 w-24 h-24 bg-indigo-100 rounded-full blur-xl opacity-60">
            </div>
            <div class="absolute -bottom-4 -left-4 w-32 h-32 bg-purple-100 rounded-full blur-xl opacity-60">
            </div>

    <!-- Close button -->
            <button
              type="button"
              class="absolute right-4 top-4 text-gray-400 hover:text-gray-500 focus:outline-none z-10"
              phx-click="close_modal"
              phx-target={@myself}
            >
              <.icon name="hero-x-mark-solid" class="h-5 w-5" />
            </button>

    <!-- Content Container -->
            <div class="relative p-8">
              <!-- Header -->
              <div class="text-center mb-8">
                <div class="flex justify-center mb-4">
                  <div class="p-2 bg-indigo-100 rounded-xl">
                    <.icon name="hero-gift-solid" class="h-8 w-8 text-indigo-600" />
                  </div>
                </div>
                <h2 class="text-2xl font-bold text-gray-900 mb-2">
                  {if @view == :sign_in, do: "Welcome Back!", else: "Create Your Wishlist"}
                </h2>
                <p class="text-sm text-gray-500">
                  <%= if @view == :sign_in do %>
                    Sign in to manage your wishlists and discover new items
                  <% else %>
                    Join us to create and share your perfect wishlist
                  <% end %>
                </p>
              </div>

    <!-- Form -->
              <.form for={@form} phx-submit="submit" phx-target={@myself} class="space-y-6">
                <div class="space-y-4">
                  <div>
                    <div class="relative">
                      <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                        <.icon name="hero-envelope" class="h-5 w-5 text-gray-400" />
                      </div>
                      <input
                        type="email"
                        name="email"
                        required
                        class="pl-10 w-full rounded-lg border-gray-200 focus:border-indigo-500 focus:ring-indigo-500"
                        placeholder="Email address"
                      />
                    </div>
                  </div>

                  <div>
                    <div class="relative">
                      <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                        <.icon name="hero-lock-closed" class="h-5 w-5 text-gray-400" />
                      </div>
                      <input
                        type="password"
                        name="password"
                        required
                        class="pl-10 w-full rounded-lg border-gray-200 focus:border-indigo-500 focus:ring-indigo-500"
                        placeholder="Password"
                      />
                    </div>
                  </div>

                  <%= if @view == :sign_up do %>
                    <div>
                      <div class="relative">
                        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                          <.icon name="hero-user" class="h-5 w-5 text-gray-400" />
                        </div>
                        <input
                          type="text"
                          name="username"
                          required
                          class="pl-10 w-full rounded-lg border-gray-200 focus:border-indigo-500 focus:ring-indigo-500"
                          placeholder="Choose a username"
                        />
                      </div>
                    </div>
                  <% end %>
                </div>

    <!-- Action Button -->
                <button
                  type="submit"
                  class="w-full px-4 py-3 text-sm font-semibold text-white bg-gradient-to-r from-indigo-600 to-purple-600 rounded-lg hover:from-indigo-500 hover:to-purple-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-all duration-300 transform hover:scale-[1.02]"
                >
                  {if @view == :sign_in, do: "Sign in", else: "Create account"}
                </button>
              </.form>

    <!-- Footer -->
              <div class="mt-6 text-center text-sm">
                <span class="text-gray-500">
                  <%= if @view == :sign_in do %>
                    New to Wishlists?
                  <% else %>
                    Already have an account?
                  <% end %>
                </span>
                <button
                  class="ml-1 text-indigo-600 hover:text-indigo-500 font-medium"
                  phx-click={if @view == :sign_in, do: "switch_to_signup", else: "switch_to_signin"}
                  phx-target={@myself}
                >
                  {if @view == :sign_in, do: "Create an account", else: "Sign in"}
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("close_modal", _, socket) do
    send(self(), :close_modal)
    {:noreply, socket}
  end

  def handle_event("submit", params, socket) do
    IO.inspect(params, label: "Auth params")
    {:noreply, socket}
  end

  def handle_event("switch_to_signup", _, socket) do
    {:noreply, assign(socket, view: :sign_up)}
  end

  def handle_event("switch_to_signin", _, socket) do
    {:noreply, assign(socket, view: :sign_in)}
  end
end
