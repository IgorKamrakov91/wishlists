defmodule WishlistsWeb.FolderLive.FolderFormComponent do
  use WishlistsWeb, :live_component
  alias Wishlists.Folders

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

              <.form for={@form} phx-submit="save" phx-target={@myself}>
                <div class="space-y-6">
                  <.input
                    field={@form[:name]}
                    type="text"
                    label="Collection Name"
                    required
                    placeholder="My Awesome Collection"
                    class="rounded-xl border-indigo-200 focus:border-purple-400 focus:ring focus:ring-purple-200"
                  />

                  <.input
                    field={@form[:description]}
                    type="textarea"
                    label="Description (optional)"
                    placeholder="What's this collection about?"
                    class="rounded-xl border-indigo-200 focus:border-purple-400 focus:ring focus:ring-purple-200"
                    rows={4}
                  />

                  <%= if @action == :edit do %>
                    <div class="flex items-center justify-between">
                      <div class="flex flex-col">
                        <span class="text-sm font-medium text-gray-700">Show Reserver Names</span>
                        <span class="text-xs text-gray-500">
                          Allow yourself to see who reserved items
                        </span>
                      </div>
                      <label class="relative inline-flex items-center cursor-pointer">
                        <input
                          type="checkbox"
                          name="folder[show_reserver_names]"
                          value="true"
                          #
                          Добавляем
                          явное
                          значение
                          true
                          class="sr-only peer"
                          checked={@form[:show_reserver_names].value}
                        />
                        <div class="w-11 h-6 bg-gray-200 rounded-full peer peer-focus:ring-4 peer-focus:ring-indigo-300 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-0.5 after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-indigo-600">
                        </div>
                      </label>
                    </div>
                  <% end %>

                  <div class="flex justify-end pt-4">
                    <.button
                      type="submit"
                      class="bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-700 hover:to-purple-700 text-white px-6 py-3 rounded-full transition-all duration-300 shadow-md hover:shadow-lg transform hover:scale-105 flex items-center space-x-2"
                    >
                      <.icon name="hero-sparkles" class="h-5 w-5" />
                      <span>{@submit_button_text}</span>
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
  def update(%{folder: folder} = assigns, socket) do
    changeset = Folders.change_folder(folder)

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
  def handle_event("save", %{"folder" => folder_params}, socket) do
    save_folder(socket, socket.assigns.action, folder_params)
  end

  defp save_folder(socket, :edit, folder_params) do
    folder_params =
      Map.update(folder_params, "show_reserver_names", false, fn
        "true" -> true
        "on" -> true
        _ -> false
      end)

    case Folders.update_folder(socket.assigns.folder, folder_params) do
      {:ok, folder} ->
        send(self(), {:folder_updated, folder})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_folder(socket, :new, folder_params) do
    folder_params = Map.put(folder_params, "user_id", socket.assigns.current_user.id)

    case Folders.create_folder(folder_params) do
      {:ok, _folder} ->
        send(self(), {:folder_created})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
