defmodule WishlistsWeb.LocaleContext do
  def put_locale(socket, locale) when locale in ["en", "ru"] do
    Gettext.put_locale(WishlistsWeb.Gettext, locale)
    Phoenix.PubSub.broadcast(Wishlists.PubSub, "locale", {:locale_changed, locale})
    socket
  end

  def subscribe do
    Phoenix.PubSub.subscribe(Wishlists.PubSub, "locale")
  end
end
