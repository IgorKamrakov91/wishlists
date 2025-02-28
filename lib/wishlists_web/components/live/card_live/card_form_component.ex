defmodule WishlistsWeb.CardLive.CardFormComponent do
  use WishlistsWeb, :live_component
  alias Wishlists.Cards

  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-gradient-to-b from-indigo-100/75 via-purple-50/75 to-pink-100/75 backdrop-blur-sm transition-opacity z-50">
      <div class="fixed inset-0 z-50 overflow-y-auto">
        <div class="flex min-h-full items-center justify-center p-4">
          <div class="relative bg-white/80 backdrop-blur-sm rounded-2xl px-6 pb-6 pt-5 shadow-xl sm:p-8 w-full max-w-2xl transform transition-all">
            <div class="absolute right-0 top-0 pr-4 pt-4">
              <button
                type="button"
                class="text-gray-400 hover:text-gray-500 transition-colors duration-200"
                phx-click="close_modal"
                phx-target={@myself}
              >
                <.icon name="hero-x-mark" class="h-6 w-6" />
              </button>
            </div>

            <div class="mt-3 sm:mt-0">
              <h3 class="text-2xl font-bold bg-gradient-to-r from-indigo-600 to-purple-600 bg-clip-text text-transparent mb-6">
                {@modal_title}
              </h3>

    <!-- URL Input Form -->
              <.form
                :if={@action == :new && !@show_manual_form}
                for={@form}
                phx-submit="fetch_data"
                phx-target={@myself}
              >
                <div class="space-y-4">
                  <.input
                    field={@form[:link_url]}
                    type="url"
                    label={gettext("Product URL")}
                    placeholder={gettext("https://example.com")}
                    class="rounded-xl border-indigo-200 focus:border-purple-400 focus:ring focus:ring-purple-200"
                  />

                  <div class="flex justify-between items-center">
                    <button
                      type="button"
                      phx-click="show_manual_form"
                      phx-target={@myself}
                      class="text-purple-600 hover:text-purple-800 text-sm flex items-center space-x-1"
                    >
                      <.icon name="hero-pencil" class="h-4 w-4" />
                      <span>{gettext("Add manually instead")}</span>
                    </button>

                    <.button
                      type="submit"
                      class="bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-700 hover:to-purple-700 text-white px-6 py-3 rounded-full transition-all duration-300 shadow-md hover:shadow-lg transform hover:scale-105 flex items-center space-x-2"
                      disabled={@card_loading}
                    >
                      <%= if @card_loading do %>
                        <div class="flex items-center space-x-2">
                          <div class="animate-spin">
                            <.icon name="hero-arrow-path" class="h-5 w-5" />
                          </div>
                          <span>{gettext("Fetching")}...</span>
                        </div>
                      <% else %>
                        <.icon name="hero-sparkles" class="h-5 w-5" />
                        <span>{gettext("Woosh!")}</span>
                      <% end %>
                    </.button>
                  </div>
                </div>
              </.form>

              <.form
                :if={@action == :edit || @show_manual_form}
                for={@form}
                phx-submit="save"
                phx-target={@myself}
              >
                <div class="space-y-6">
                  <div class={[
                    "relative rounded-xl transition-all duration-300",
                    @form[:image_url].value && @form[:image_url].value != "" &&
                      "h-48 bg-[250,250,250] mb-20",
                    !@form[:image_url].value || (@form[:image_url].value == "" && "h-auto")
                  ]}>
                    <%= if @form[:image_url].value && @form[:image_url].value != "" do %>
                      <img
                        src={@form[:image_url].value}
                        alt=""
                        class="w-full h-full object-contain rounded-t-xl"
                      />
                      <div class="absolute -bottom-16 left-0 right-0">
                        <.input
                          field={@form[:image_url]}
                          type="text"
                          label={gettext("Image URL")}
                          class="rounded-xl border-indigo-200 focus:border-purple-400 focus:ring focus:ring-purple-200"
                          placeholder={gettext("Image URL")}
                        />
                      </div>
                    <% else %>
                      <.input
                        field={@form[:image_url]}
                        type="text"
                        label={gettext("Image URL")}
                        class="rounded-xl border-indigo-200 focus:border-purple-400 focus:ring focus:ring-purple-200"
                        placeholder={gettext("Paste image URL here")}
                      />
                    <% end %>
                  </div>

                  <.input
                    field={@form[:link_url]}
                    type="url"
                    label={gettext("Product URL")}
                    required
                    placeholder="https://example.com"
                    class="rounded-xl border-indigo-200 focus:border-purple-400 focus:ring focus:ring-purple-200"
                  />

                  <.input
                    field={@form[:title]}
                    type="text"
                    label={gettext("Title")}
                    required
                    placeholder={gettext("Product title")}
                    class="rounded-xl border-indigo-200 focus:border-purple-400 focus:ring focus:ring-purple-200"
                  />

                  <.input
                    field={@form[:description]}
                    type="textarea"
                    label={gettext("Description (optional)")}
                    rows="4"
                    placeholder={gettext("Product description")}
                    class="rounded-xl border-indigo-200 focus:border-purple-400 focus:ring focus:ring-purple-200"
                  />

                  <.input
                    field={@form[:price]}
                    type="text"
                    label={gettext("Price (in RUB)")}
                    required
                    pattern="[0-9]*\.?[0-9]*"
                    inputmode="decimal"
                    placeholder="3000.00"
                    class="rounded-xl border-indigo-200 focus:border-purple-400 focus:ring focus:ring-purple-200"
                  />

                  <div class="flex justify-end pt-4">
                    <.button
                      type="submit"
                      class="bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-700 hover:to-purple-700 text-white px-6 py-3 rounded-full transition-all duration-300 shadow-md hover:shadow-lg transform hover:scale-105 flex items-center space-x-2"
                    >
                      <.icon name="hero-sparkles" class="h-5 w-5" />
                      <span>{gettext("Save")}</span>
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
  def update(%{card: card, action: :edit} = assigns, socket) do
    changeset = Cards.change_card(card)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(form: to_form(changeset))
     |> assign(card_loading: false)
     |> assign(show_manual_form: false)}
  end

  def update(%{card: _card} = assigns, socket) do
    changeset = Cards.change_card(%Cards.Card{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(form: to_form(changeset))
     |> assign(card_loading: false)
     |> assign(show_manual_form: false)}
  end

  @impl true
  def handle_event("show_manual_form", _, socket) do
    {:noreply, assign(socket, show_manual_form: true)}
  end

  @impl true
  def handle_event("save", %{"card" => card_params}, socket) do
    save_card(socket, socket.assigns.action, card_params)
  end

  @impl true
  def handle_event("fetch_data", %{"card" => %{"link_url" => url}}, socket)
      when byte_size(url) > 0 do
    socket = socket |> assign(card_loading: true)

    case MarketplaceScrapper.fetch_and_extract(url) do
      {:ok, %{"title" => title, "description" => description, "image" => image, "price" => price}} ->
        parsed_price =
          case Float.parse(price) do
            {number, _} -> number
            :error -> nil
          end

        changeset =
          Cards.change_card(%Cards.Card{}, %{
            "title" => title,
            "description" => description,
            "image_url" => image,
            "link_url" => url,
            "price" => parsed_price
          })

        {:noreply,
         socket
         |> assign(card_loading: false)
         |> assign(show_manual_form: true)
         |> assign(form: to_form(changeset))}

      {:error, _reason} ->
        changeset = Cards.change_card(%Cards.Card{}, %{"link_url" => url})

        {:noreply,
         socket
         |> assign(card_loading: false)
         |> assign(show_manual_form: true)
         |> assign(form: to_form(changeset))
         |> put_flash(
           :error,
           gettext("Could not fetch data automatically. Please fill in the details manually.")
         )}
    end
  end

  def handle_event("fetch_data", _, socket), do: {:noreply, socket}

  @impl true
  def handle_event("close_modal", _, socket) do
    send(self(), :close_modal)
    {:noreply, socket}
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

  defp save_card(socket, :new, card_params) do
    is_suggestion = Map.get(socket.assigns, :is_suggestion, false)
    folder = Map.get(socket.assigns, :folder)

    card_params =
      if is_suggestion do
        card_params
        |> Map.put("status", "pending")
        |> Map.put("user_id", folder.user_id)
        |> add_suggester_info(socket.assigns)
      else
        card_params
        |> Map.put("user_id", socket.assigns.current_user.id)
      end

    case Cards.create_card(card_params) do
      {:ok, card} ->
        cond do
          is_suggestion ->
            send(self(), {:card_suggested, card})
            {:noreply, socket}

          folder ->
            case Cards.assign_card_to_folder(card.id, folder.id) do
              {:ok, _} ->
                send(self(), {:card_created})
                {:noreply, socket}

              {:error, _} ->
                {:noreply,
                 socket
                 |> put_flash(:error, gettext("Failed to assign card to folder"))
                 |> assign(form: to_form(Cards.change_card(card)))}
            end

          true ->
            send(self(), {:card_created})
            {:noreply, socket}
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp add_suggester_info(params, assigns) do
    cond do
      assigns.current_user ->
        Map.put(params, "suggested_by_user_id", assigns.current_user.id)

      assigns.guest_viewer ->
        Map.put(params, "suggested_by_guest_id", assigns.guest_viewer.id)

      true ->
        params
    end
  end
end
