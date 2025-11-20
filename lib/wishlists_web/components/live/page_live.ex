defmodule WishlistsWeb.PageLive do
  use WishlistsWeb, :live_view
  alias Wishlists.Accounts.Guardian
  alias WishlistsWeb.LocaleContext
  alias Wishlists.Accounts

  on_mount {WishlistsWeb.UserAuth, :mount_current_user}

  def mount(params, session, socket) do
    locale =
      cond do
        params["locale"] in ["en", "ru"] ->
          params["locale"]

        socket.assigns[:current_user] ->
          Accounts.get_user_locale(socket.assigns.current_user)

        session["locale"] ->
          session["locale"]

        true ->
          "ru"
      end

    Gettext.put_locale(WishlistsWeb.Gettext, locale)

    case Guardian.decode_and_verify(session["guardian_default_token"]) do
      {:ok, claims} ->
        case Guardian.resource_from_claims(claims) do
          {:ok, user} ->
            # Only redirect if we have a valid user
            {:ok, push_navigate(socket, to: ~p"/dashboard")}

          {:error, _reason} ->
            # Token is valid but user not found - clear invalid session
            {:ok,
             socket
             |> assign(show_auth_modal: false)
             |> assign(locale: locale)
             |> assign(translations: get_translations(locale))
             |> assign(current_user: nil)
             |> clear_flash()}
        end

      {:error, _reason} ->
        {:ok,
         socket
         |> assign(show_auth_modal: false)
         |> assign(locale: locale)
         |> assign(translations: get_translations(locale))
         |> assign(current_user: nil)
         |> clear_flash()}
    end
  end

  def handle_event("switch_locale", %{"locale" => locale}, socket) when locale in ["en", "ru"] do
    Gettext.put_locale(WishlistsWeb.Gettext, locale)

    socket =
      if socket.assigns.current_user do
        case Accounts.update_user_locale(socket.assigns.current_user, locale) do
          {:ok, updated_user} ->
            assign(socket, :current_user, updated_user)

          {:error, _} ->
            socket
        end
      else
        socket
      end

    {:noreply,
     socket
     |> assign(:locale, locale)
     |> assign(:translations, get_translations(locale))
     |> push_event("store-locale", %{locale: locale})
     |> push_patch(to: ~p"/?locale=#{locale}")}
  end

  def handle_event("open_auth_modal", _, socket) do
    {:noreply, assign(socket, show_auth_modal: true)}
  end

  def handle_info({:login_success, user, token}, socket) do
    current_locale = socket.assigns.locale || "ru"

    {:ok, _updated_user} = Wishlists.Accounts.update_user_locale(user, current_locale)

    {:noreply,
     socket
     |> clear_flash()
     |> redirect(to: ~p"/auth/set_session?token=#{token}&locale=#{current_locale}")}
  end

  def handle_info({:login_error, message}, socket) do
    {:noreply,
     socket
     |> put_flash(:error, message)
     |> assign(show_auth_modal: true)}
  end

  def handle_info(:close_modal, socket) do
    {:noreply, assign(socket, show_auth_modal: false)}
  end

  def handle_info({:locale_changed, locale}, socket) do
    {:noreply, assign(socket, :locale, locale)}
  end

  def handle_params(%{"locale" => locale}, _uri, socket) when locale in ["en", "ru"] do
    {:noreply, LocaleContext.put_locale(socket, locale)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  defp get_translations(locale) do
    Gettext.with_locale(locale, fn ->
      %{
        "title" => gettext("Wishlists Manager"),
        "description" =>
          gettext(
            "Create and manage your wishlists effortlessly. Keep track of all the things you dream about!"
          ),
        "get_started" => gettext("Get Started"),
        "contact" => gettext("Contact"),
        "quick_links" => gettext("Quick Links"),
        "about_us" => gettext("About Us"),
        "terms" => gettext("Terms of Service"),
        "privacy" => gettext("Privacy Policy"),
        "follow_us" => gettext("Follow Us"),
        "copyright" => gettext("© 2025 Wishlists Manager."),
        "email" => gettext("Email: i.kamrakov@yahoo.com"),

        # Translations for HowItWorksComponent
        "how_it_works" => gettext("How It Works"),
        "create_wishlist" => gettext("Create Your Wishlist"),
        "create_wishlist_description" =>
          gettext(
            "Sign up and create your first wishlist. Add items you'd love to receive as gifts."
          ),
        "share_with_friends" => gettext("Share With Friends"),
        "share_with_friends_description" =>
          gettext(
            "Share your wishlist with friends and family using a unique link or invite them directly."
          ),
        "receive_gifts" => gettext("Receive Perfect Gifts"),
        "receive_gifts_description" =>
          gettext(
            "Your friends can mark items as reserved, ensuring you get exactly what you want without duplicates."
          ),
        "try_it_now" => gettext("Try It Now")
      }
    end)
  end
end
