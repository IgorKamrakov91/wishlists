defmodule WishlistsWeb.Locale do
  def put_locale(socket, locale) when locale in ["en", "ru"] do
    Gettext.put_locale(WishlistsWeb.Gettext, locale)
    Phoenix.LiveView.push_event(socket, "set-locale", %{locale: locale})
    socket
  end
end
