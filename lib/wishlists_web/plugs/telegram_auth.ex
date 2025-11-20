defmodule WishlistsWeb.Plugs.TelegramAuth do
  @behaviour Plug

  import Plug.Conn

  alias Wishlists.Accounts
  alias Wishlists.Accounts.Guardian

  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    cond do
      telegram_session_active?(conn) ->
        conn
        |> assign(:telegram_mode, true)

      has_web_session?(conn) ->
        # Allow access if user is logged in via web (for dev/testing)
        # but don't set telegram_mode
        conn
        |> assign(:telegram_mode, false)

      true ->
        authenticate(conn)
    end
  end

  defp telegram_session_active?(conn) do
    get_session(conn, :telegram_mode) && Guardian.Plug.current_resource(conn)
  end

  defp has_web_session?(conn) do
    case Guardian.Plug.current_resource(conn) do
      %Wishlists.Accounts.User{} = user ->
        # User is authenticated via web, allow access
        true

      _ ->
        false
    end
  end

  defp authenticate(conn) do
    case fetch_init_data(conn) do
      {:ok, init_data} ->
        with {:ok, params} <- verify_init_data(init_data),
             {:ok, user_attrs} <- build_user_attrs(params),
             {:ok, user} <- Accounts.upsert_telegram_user(user_attrs) do
          conn
          |> Guardian.Plug.sign_in(Wishlists.Accounts.Guardian, user)
          |> assign(:telegram_mode, true)
          |> assign(:current_user, user)
          |> put_session(:telegram_mode, true)
        else
          {:error, reason} ->
            Logger.warning("Telegram authentication failed: #{inspect(reason)}")

            conn
            |> send_resp(:unauthorized, "Invalid Telegram session")
            |> halt()
        end

      {:error, :missing_init_data} ->
        # No initData provided and no web session - require authentication
        Logger.warning("Telegram authentication failed: :missing_init_data")

        conn
        |> send_resp(:unauthorized, "Invalid Telegram session")
        |> halt()
    end
  end

  defp fetch_init_data(conn) do
    init_data =
      conn.params["init_data"] ||
        conn.params["initData"] ||
        conn.params["tg_init_data"] ||
        conn.params["tg_web_app_data"] ||
        List.first(get_req_header(conn, "x-telegram-init-data"))

    case init_data do
      binary when is_binary(binary) and byte_size(binary) > 0 ->
        {:ok, binary}

      _ ->
        {:error, :missing_init_data}
    end
  end

  defp verify_init_data(init_data) when is_binary(init_data) do
    with {:ok, params} <- decode_query(init_data),
         {:ok, bot_token} <- fetch_bot_token(),
         :ok <- validate_hash(params, bot_token),
         :ok <- validate_auth_date(params) do
      {:ok, params}
    end
  end

  defp verify_init_data(_), do: {:error, :invalid_init_data}

  defp decode_query(init_data) do
    {:ok, URI.decode_query(init_data)}
  rescue
    ArgumentError -> {:error, :invalid_init_data}
  end

  defp fetch_bot_token do
    case Application.get_env(:wishlists, :telegram_bot_token) do
      token when is_binary(token) and byte_size(token) > 0 -> {:ok, token}
      _ -> {:error, :missing_bot_token}
    end
  end

  defp validate_hash(params, bot_token) do
    provided_hash = params["hash"]

    if is_binary(provided_hash) do
      secret_key = :crypto.mac(:hmac, :sha256, "WebAppData", bot_token)

      data_check_string =
        params
        |> Enum.reject(fn {key, _value} -> key == "hash" end)
        |> Enum.sort()
        |> Enum.map_join("\n", fn {key, value} -> "#{key}=#{value}" end)

      computed_hash =
        :crypto.mac(:hmac, :sha256, secret_key, data_check_string)
        |> Base.encode16(case: :lower)

      provided_hash = String.downcase(provided_hash)

      if byte_size(computed_hash) == byte_size(provided_hash) &&
           Plug.Crypto.secure_compare(computed_hash, provided_hash) do
        :ok
      else
        {:error, :invalid_hash}
      end
    else
      {:error, :missing_hash}
    end
  end

  defp validate_auth_date(params) do
    ttl_seconds = Application.get_env(:wishlists, :telegram_init_ttl_seconds, 86_400)

    params
    |> Map.get("auth_date")
    |> parse_integer()
    |> case do
      nil ->
        {:error, :invalid_auth_date}

      auth_date ->
        with {:ok, timestamp} <- DateTime.from_unix(auth_date),
             diff when diff >= 0 and diff <= ttl_seconds <-
               DateTime.diff(DateTime.utc_now(), timestamp) do
          :ok
        else
          _ -> {:error, :expired_init_data}
        end
    end
  end

  defp build_user_attrs(%{"user" => user_payload}) when is_binary(user_payload) do
    case Jason.decode(user_payload) do
      {:ok, %{"id" => id} = user} ->
        case parse_integer(id) do
          nil ->
            {:error, :invalid_user_payload}

          telegram_id ->
            {:ok,
             %{
               "telegram_id" => telegram_id,
               "telegram_username" => user["username"],
               "telegram_photo_url" => user["photo_url"],
               "auth_provider" => "telegram"
             }}
        end

      _ ->
        {:error, :invalid_user_payload}
    end
  rescue
    Jason.DecodeError ->
      {:error, :invalid_user_payload}
  end

  defp build_user_attrs(_), do: {:error, :invalid_user_payload}

  defp parse_integer(nil), do: nil

  defp parse_integer(value) when is_integer(value), do: value

  defp parse_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {parsed, _} -> parsed
      :error -> nil
    end
  end

  defp parse_integer(_), do: nil
end
