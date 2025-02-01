defmodule WishlistsWeb.CardLive.CardFormComponent do
  use WishlistsWeb, :live_component
  alias Wishlists.Cards

  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity z-50">
      <div class="fixed inset-0 z-50 overflow-y-auto">
        <div class="flex min-h-full items-center justify-center p-4">
          <div class="relative bg-white rounded-lg px-4 pb-4 pt-5 shadow-xl sm:p-6">
            <div class="absolute right-0 top-0 pr-4 pt-4">
              <button
                type="button"
                class="text-gray-400 hover:text-gray-500"
                phx-click="close_modal"
                phx-target={@myself}
              >
                <.icon name="hero-x-mark-solid" class="h-6 w-6" />
              </button>
            </div>

            <div class="mt-3 text-center sm:mt-0 sm:text-left">
              <h3 class="text-lg font-semibold leading-6 text-gray-900 mb-4">
                {@modal_title}
              </h3>

              <.form for={@form} phx-submit="fetch_data" phx-target={@myself}>
                <div class="space-y-4">
                  <.input
                    field={@form[:link_url]}
                    type="url"
                    label="Product URL"
                    placeholder="Paste product URL here"
                  />

                  <div class="flex justify-end">
                    <.button type="submit" class="bg-indigo-600" disabled={@loading}>
                      <%= if @loading do %>
                        <div class="flex items-center">
                          <div class="animate-spin mr-2">
                            <.icon name="hero-arrow-path" class="h-5 w-5" />
                          </div>
                          Fetching...
                        </div>
                      <% else %>
                        Fetch Product
                      <% end %>
                    </.button>
                  </div>
                </div>
              </.form>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{card: _card} = assigns, socket) do
    changeset = Cards.change_card(%Cards.Card{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(form: to_form(changeset))
     |> assign(loading: false)}
  end

  @impl true
  def handle_event("fetch_data", %{"card" => %{"link_url" => url}}, socket)
      when byte_size(url) > 0 do
    socket = assign(socket, loading: true)

    case MarketplaceScrapper.fetch_and_extract(url) do
      %{"title" => title, "description" => description, "image" => image} = _data ->
        card_params = %{
          "title" => title,
          "description" => description,
          "image_url" => image,
          "link_url" => url,
          "user_id" => socket.assigns.current_user.id
        }

        case Cards.create_card(card_params) do
          {:ok, _card} ->
            send(self(), {:card_created})
            {:noreply, assign(socket, loading: false)}

          {:error, _changeset} ->
            {:noreply,
             socket
             |> assign(loading: false)
             |> put_flash(:error, "Failed to create card")}
        end

      :error ->
        {:noreply,
         socket
         |> assign(loading: false)
         |> put_flash(:error, "Failed to fetch product data")}
    end
  end

  def handle_event("fetch_data", _, socket), do: {:noreply, socket}

  @impl true
  def handle_event("close_modal", _, socket) do
    send(self(), :close_modal)
    {:noreply, socket}
  end
end
