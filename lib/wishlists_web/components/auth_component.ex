defmodule WishlistsWeb.AuthComponent do
  use WishlistsWeb, :live_component
  alias Wishlists.Accounts

  def mount(socket) do
    {:ok,
     socket
     |> assign(view: :sign_in)
     |> assign(form_data: %{"email" => "", "password" => "", "username" => ""})
     |> assign(form: to_form(%{}, as: :user))
     |> assign(error_message: nil)
     |> assign(password_focus: false)
     |> assign(password_requirement_met: false)}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-black bg-opacity-50 transition-opacity z-50">
      <div class="fixed inset-0 z-50 overflow-y-auto">
        <div class="flex min-h-full items-center justify-center p-4">
          <.modal_content {assigns} />
        </div>
      </div>
    </div>
    """
  end

  defp modal_content(assigns) do
    ~H"""
    <div class="relative bg-white w-full max-w-md rounded-xl shadow-2xl transform transition-all">
      <.decorative_elements />
      <.close_button myself={@myself} />
      <div class="relative p-8">
        <.modal_header view={@view} />
        <.error_message error_message={@error_message} />
        <.auth_form
          form={@form}
          form_data={@form_data}
          view={@view}
          password_focus={@password_focus}
          password_requirement_met={@password_requirement_met}
          myself={@myself}
        />
        <.footer view={@view} myself={@myself} />
      </div>
    </div>
    """
  end

  defp decorative_elements(assigns) do
    ~H"""
    <div class="absolute -top-4 -right-4 w-24 h-24 bg-indigo-100 rounded-full blur-xl opacity-60">
    </div>
    <div class="absolute -bottom-4 -left-4 w-32 h-32 bg-purple-100 rounded-full blur-xl opacity-60">
    </div>
    """
  end

  defp close_button(assigns) do
    ~H"""
    <button
      type="button"
      class="absolute right-4 top-4 text-gray-400 hover:text-gray-500 focus:outline-none z-10"
      phx-click="close_modal"
      phx-target={@myself}
    >
      <span class="sr-only">{gettext("Close")}</span>
      <.icon name="hero-x-mark-solid" class="h-5 w-5" />
    </button>
    """
  end

  defp modal_header(assigns) do
    ~H"""
    <div class="text-center mb-8">
      <div class="flex justify-center mb-4">
        <div class="p-2 bg-indigo-100 rounded-xl">
          <.icon name="hero-gift-solid" class="h-8 w-8 text-indigo-600" />
        </div>
      </div>
      <h2 class="text-2xl font-bold text-gray-900 mb-2">
        {if @view == :sign_in, do: gettext("Welcome Back!"), else: gettext("Create Your Wishlist")}
      </h2>
      <p class="text-sm text-gray-500">
        {if @view == :sign_in,
          do: gettext("Sign in to manage your wishlists and discover new items"),
          else: gettext("Join us to create and share your perfect wishlist")}
      </p>
    </div>
    """
  end

  defp auth_form(assigns) do
    ~H"""
    <.form :let={_f} for={@form} phx-submit="submit" phx-target={@myself} class="space-y-6">
      <.email_input form_data={@form_data} myself={@myself} />
      <.password_input
        form_data={@form_data}
        password_focus={@password_focus}
        password_requirement_met={@password_requirement_met}
        view={@view}
        myself={@myself}
      />
      <%= if @view == :sign_up do %>
        <.username_input form_data={@form_data} myself={@myself} />
      <% end %>
      <.submit_button view={@view} />
    </.form>
    """
  end

  defp email_input(assigns) do
    ~H"""
    <div class="relative">
      <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
        <.icon name="hero-envelope" class="h-5 w-5 text-gray-400" />
      </div>
      <input
        type="email"
        name="email"
        value={@form_data["email"]}
        phx-change="form_changed"
        phx-target={@myself}
        required
        class="pl-10 w-full rounded-lg border-gray-200 focus:border-indigo-500 focus:ring-indigo-500"
        placeholder={gettext("Email address")}
      />
    </div>
    """
  end

  defp password_input(assigns) do
    ~H"""
    <div>
      <div class="relative">
        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
          <.icon name="hero-lock-closed" class="h-5 w-5 text-gray-400" />
        </div>
        <input
          type="password"
          name="password"
          value={@form_data["password"]}
          required
          phx-keyup="validate_password"
          phx-target={@myself}
          class="pl-10 w-full rounded-lg border-gray-200 focus:border-indigo-500 focus:ring-indigo-500"
          placeholder={gettext("Password")}
          phx-focus="password_focus"
          phx-blur="password_blur"
        />
      </div>
      <div class={[
        "transition-all duration-300 ease-in-out overflow-hidden",
        (@password_focus && @view == :sign_up && "max-h-[200px] opacity-100 mt-2") ||
          "max-h-0 opacity-0"
      ]}>
        <.password_requirements
          :if={@view == :sign_up}
          password_requirement_met={@password_requirement_met}
        />
      </div>
    </div>
    """
  end

  defp password_requirements(assigns) do
    ~H"""
    <div class="text-sm">
      <p class="font-medium text-gray-700 mb-1">{gettext("Password requirement:")}</p>
      <.requirement_item met={@password_requirement_met} text={gettext("At least 8 characters")} />
    </div>
    """
  end

  defp requirement_item(assigns) do
    ~H"""
    <li class={[(@met && "text-green-600") || "text-gray-500"]}>
      <.icon
        name={(@met && "hero-check-circle-mini") || "hero-minus-circle-mini"}
        class="inline-block h-4 w-4 mr-1"
      />
      {@text}
    </li>
    """
  end

  defp username_input(assigns) do
    ~H"""
    <div class="relative">
      <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
        <.icon name="hero-user" class="h-5 w-5 text-gray-400" />
      </div>
      <input
        type="text"
        name="username"
        value={@form_data["username"]}
        phx-change="form_changed"
        phx-target={@myself}
        required
        class="pl-10 w-full rounded-lg border-gray-200 focus:border-indigo-500 focus:ring-indigo-500"
        placeholder={gettext("Choose a username")}
      />
    </div>
    """
  end

  defp submit_button(assigns) do
    ~H"""
    <button
      type="submit"
      class="w-full px-4 py-3 text-sm font-semibold text-white bg-gradient-to-r from-indigo-600 to-purple-600 rounded-lg hover:from-indigo-500 hover:to-purple-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-all duration-300 transform hover:scale-[1.02]"
    >
      {if @view == :sign_in, do: gettext("Sign in"), else: gettext("Create account")}
    </button>
    """
  end

  defp footer(assigns) do
    ~H"""
    <div class="mt-6 text-center text-sm">
      <span class="text-gray-500">
        {if @view == :sign_in,
          do: gettext("New to Wishlists?"),
          else: gettext("Already have an account?")}
      </span>
      <button
        class="ml-1 text-indigo-600 hover:text-indigo-500 font-medium"
        phx-click={if @view == :sign_in, do: "switch_to_signup", else: "switch_to_signin"}
        phx-target={@myself}
      >
        {if @view == :sign_in, do: gettext("Create an account"), else: gettext("Sign in")}
      </button>
    </div>
    """
  end

  # Event handlers remain the same
  def handle_event("close_modal", _, socket) do
    send(self(), :close_modal)
    {:noreply, socket}
  end

  def handle_event("submit", _params, socket) do
    if socket.assigns.view == :sign_in do
      case Wishlists.Accounts.authenticate_user(
             socket.assigns.form_data["email"],
             socket.assigns.form_data["password"]
           ) do
        {:ok, user} ->
          case Wishlists.Accounts.Guardian.encode_and_sign(user) do
            {:ok, token, _claims} ->
              send(self(), {:login_success, user, token})
              {:noreply, socket}

            {:error, _reason} ->
              {:noreply, assign(socket, error_message: gettext("Authentication failed"))}
          end

        {:error, _reason} ->
          {:noreply, assign(socket, error_message: gettext("Invalid email or password"))}
      end
    else
      case Accounts.register_user(socket.assigns.form_data) do
        {:ok, user} ->
          case Wishlists.Accounts.Guardian.encode_and_sign(user) do
            {:ok, token, _claims} ->
              send(self(), {:login_success, user, token})
              {:noreply, socket}

            {:error, _reason} ->
              {:noreply, assign(socket, error_message: gettext("Authentication failed"))}
          end

        {:error, changeset} ->
          error_message = format_registration_errors(changeset)
          {:noreply, assign(socket, error_message: error_message)}
      end
    end
  end

  def handle_event("validate_password", %{"value" => password}, socket) do
    requirement_met = String.length(password) >= 8
    form_data = Map.put(socket.assigns.form_data, "password", password)

    {:noreply,
     socket
     |> assign(password_requirement_met: requirement_met)
     |> assign(form_data: form_data)}
  end

  def handle_event("switch_to_signup", _, socket) do
    {:noreply,
     socket
     |> assign(view: :sign_up)
     |> assign(error_message: nil)}
  end

  def handle_event("switch_to_signin", _, socket) do
    {:noreply,
     socket
     |> assign(view: :sign_in)
     |> assign(error_message: nil)}
  end

  def handle_event("password_focus", _params, socket) do
    {:noreply, assign(socket, password_focus: true)}
  end

  def handle_event("password_blur", _params, socket) do
    {:noreply, assign(socket, password_focus: false)}
  end

  def handle_event("form_changed", %{"_target" => [field]} = params, socket) do
    form_data =
      Map.put(
        socket.assigns.form_data,
        field,
        params[field]
      )

    {:noreply, assign(socket, form_data: form_data)}
  end

  defp error_message(assigns) do
    ~H"""
    <%= if @error_message do %>
      <div class="mb-6 rounded-md bg-red-50/50 p-2.5 transition-all">
        <div class="flex items-center gap-2">
          <.icon name="hero-exclamation-circle-mini" class="h-4 w-4 text-red-500/80" />
          <p class="text-sm text-red-600/90">
            {@error_message}
          </p>
        </div>
      </div>
    <% end %>
    """
  end

  defp format_registration_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn
        {key, value}, acc when is_list(value) ->
          String.replace(acc, "%{#{key}}", Enum.join(value, ", "))

        {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, errors} ->
      field_name = Phoenix.Naming.humanize(field)
      "#{field_name} #{Enum.join(errors, ", ")}"
    end)
    |> Enum.join(". ")
  end
end
