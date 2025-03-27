defmodule WishlistsWeb.Plugs.Locale do
  import Plug.Conn

  @supported_locales ["en", "ru"]

  def init(default), do: default

  def call(conn, _opts) do
    locale =
      cond do
        conn.params["locale"] && conn.params["locale"] in @supported_locales ->
          conn.params["locale"]

        get_session(conn, :locale) ->
          get_session(conn, :locale)

        conn.assigns[:current_user] && conn.assigns[:current_user].locale ->
          conn.assigns[:current_user].locale

        accept_language = get_req_header(conn, "accept-language") |> List.first() ->
          parse_accept_language(accept_language)

        true ->
          "ru"
      end

    conn
    |> put_session(:locale, locale)
    |> assign(:locale, locale)
  end

  defp parse_accept_language(nil), do: "ru"

  defp parse_accept_language(accept_language) do
    accept_language
    |> String.split(",")
    |> Enum.map(&parse_language_option/1)
    |> Enum.sort(&(&1.quality > &2.quality))
    |> Enum.find_value("ru", fn lang ->
      if lang.code in @supported_locales, do: lang.code
    end)
  end

  defp parse_language_option(option) do
    [language | quality] = String.split(option, ";q=")

    quality =
      case quality do
        [] -> 1.0
        [q] -> String.to_float(q)
      end

    %{code: String.slice(language, 0, 2), quality: quality}
  end
end
