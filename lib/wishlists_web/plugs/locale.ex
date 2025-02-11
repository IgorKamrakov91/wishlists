defmodule WishlistsWeb.Plugs.Locale do
  import Plug.Conn

  def init(default), do: default

  def call(conn, _opts) do
    locale = get_locale_from_conn(conn)
    Gettext.put_locale(WishlistsWeb.Gettext, locale)
    put_session(conn, :locale, locale)
  end

  defp get_locale_from_conn(conn) do
    (conn.params["locale"] || get_session(conn, :locale) || "en")
    |> check_locale()
  end

  defp check_locale(locale) when locale in ["en", "ru"], do: locale
  defp check_locale(_), do: "en"
end
