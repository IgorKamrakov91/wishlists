defmodule WishlistsWeb.FolderLive.FolderFormComponent do
  use WishlistsWeb, :live_component
  alias Wishlists.Folders
  alias Wishlists.Folders.Folder

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
                <.input field={@form[:name]} type="text" label="Folder Name" required />
                <.input field={@form[:description]} type="textarea" label="Description (optional)" />

                <:actions>
                  <button
                    type="button"
                    phx-click="close_modal"
                    phx-target={@myself}
                    class="rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500"
                  >
                    {@submit_button_text}
                  </button>
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
    changeset =
      case assigns.action do
        :edit -> Folders.change_folder(assigns.folder)
        :new -> Folders.change_folder(%Folder{})
      end

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
