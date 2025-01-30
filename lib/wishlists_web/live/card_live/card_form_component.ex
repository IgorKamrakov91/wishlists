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

              <.simple_form for={@form} phx-submit="save" phx-target={@myself}>
                <.input field={@form[:title]} type="text" label="Card Title" required />
                <.input field={@form[:description]} type="textarea" label="Description" />
                <.input field={@form[:image_url]} type="url" label="Image URL" />
                <.input field={@form[:link_url]} type="url" label="Link URL" />

                <:actions>
                  <.button type="button" phx-click="close_modal" phx-target={@myself} class="bg-white">
                    Cancel
                  </.button>
                  <.button type="submit" class="bg-brand">
                    {@submit_button_text}
                  </.button>
                </:actions>
              </.simple_form>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    changeset = Cards.change_card(%Cards.Card{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(form: to_form(changeset))}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    send(self(), :close_modal)
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"card" => card_params}, socket) do
    card_params = Map.put(card_params, "user_id", socket.assigns.current_user.id)

    case Cards.create_card(card_params) do
      {:ok, _card} ->
        send(self(), {:card_created})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
