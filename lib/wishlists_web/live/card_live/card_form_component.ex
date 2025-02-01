defmodule WishlistsWeb.CardLive.CardFormComponent do
  use WishlistsWeb, :live_component
  alias Wishlists.Cards

  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity z-50">
      <div class="fixed inset-0 z-50 overflow-y-auto">
        <div class="flex min-h-full items-center justify-center p-4">
          <div class="relative bg-white rounded-lg px-6 pb-6 pt-5 shadow-xl sm:p-8 w-full max-w-2xl">
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

            <div class="mt-3 sm:mt-0">
              <h3 class="text-xl font-semibold leading-6 text-gray-900 mb-6">
                {@modal_title}
              </h3>

              <.form :if={@action == :new} for={@form} phx-submit="fetch_data" phx-target={@myself}>
                <div class="space-y-4">
                  <.input
                    field={@form[:link_url]}
                    type="url"
                    label="Product URL"
                    placeholder="Paste product URL here"
                  />

                  <div class="flex justify-center">
                    <.button type="submit" class="bg-indigo-600" disabled={@card_loading}>
                      <%= if @card_loading do %>
                        <div class="flex items-center">
                          <div class="animate-spin mr-2">
                            <.icon name="hero-arrow-path" class="h-5 w-5" />
                          </div>
                          Fetching...
                        </div>
                      <% else %>
                        Wooosh!
                      <% end %>
                    </.button>
                  </div>
                </div>
              </.form>

              <.form :if={@action == :edit} for={@form} phx-submit="save" phx-target={@myself}>
                <div class="space-y-6">
                  <!-- Product image preview if available -->
                  <%= if @card.image_url do %>
                    <div class="relative w-full h-48 bg-gray-100 rounded-lg overflow-hidden">
                      <img src={@card.image_url} alt="" class="w-full h-full object-contain" />
                    </div>
                  <% end %>

                  <.input field={@form[:title]} type="text" label="Title" />

                  <.input field={@form[:description]} type="textarea" label="Description" rows="4" />

                  <.input
                    field={@form[:price]}
                    type="text"
                    label="Price (in RUB)"
                    value={format_price(@card.price)}
                    pattern="[0-9]*\.?[0-9]*"
                    inputmode="decimal"
                  />

                  <div class="flex justify-end pt-4">
                    <.button type="submit" class="bg-indigo-600 w-full sm:w-auto">
                      Save Changes
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

  # Helper function to format price
  defp format_price(nil), do: ""
  defp format_price(price) when is_float(price), do: :erlang.float_to_binary(price, decimals: 2)
  defp format_price(price), do: price

  @impl true
  def update(%{card: card, action: :edit} = assigns, socket) do
    changeset = Cards.change_card(card)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(form: to_form(changeset))
     |> assign(card_loading: false)}
  end

  def update(%{card: _card} = assigns, socket) do
    changeset = Cards.change_card(%Cards.Card{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(form: to_form(changeset))
     |> assign(card_loading: false)}
  end

  @impl true
  def handle_event("save", %{"card" => card_params}, socket) do
    save_card(socket, socket.assigns.action, card_params)
  end

  defp save_card(socket, :edit, card_params) do
    case Cards.update_card(socket.assigns.card, card_params) do
      {:ok, _card} ->
        send(self(), {:card_updated})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("fetch_data", %{"card" => %{"link_url" => url}}, socket)
      when byte_size(url) > 0 do
    socket = socket |> assign(card_loading: true)

    IO.inspect(socket, label: "socket")

    case MarketplaceScrapper.fetch_and_extract(url) do
      {:ok, %{"title" => title, "description" => description, "image" => image, "price" => price}} ->
        card_params = %{
          "title" => title,
          "description" => description,
          "image_url" => image,
          "link_url" => url,
          "price" => price,
          "user_id" => socket.assigns.current_user.id
        }

        case Cards.create_card(card_params) do
          {:ok, _card} ->
            send(self(), {:card_created})
            {:noreply, assign(socket, card_loading: false)}

          {:error, _changeset} ->
            {:noreply,
             socket
             |> assign(card_loading: false)
             |> put_flash(:error, "Failed to create card")}
        end

      {:error, :fetch_failed} ->
        {:noreply,
         socket
         |> assign(card_loading: false)
         |> put_flash(:error, "Failed to fetch the webpage. Please check if the URL is correct.")}

      {:error, :parse_failed} ->
        {:noreply,
         socket
         |> assign(card_loading: false)
         |> put_flash(:error, "Failed to parse product data from the webpage")}

      {:error, :api_failed} ->
        {:noreply,
         socket
         |> assign(card_loading: false)
         |> put_flash(:error, "AI processing failed. Please try again later.")}
    end
  end

  def handle_event("fetch_data", _, socket), do: {:noreply, socket}

  @impl true
  def handle_event("close_modal", _, socket) do
    send(self(), :close_modal)
    {:noreply, socket}
  end
end
