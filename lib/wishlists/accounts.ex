defmodule Wishlists.Accounts do
  alias Wishlists.Repo
  alias Wishlists.Accounts.{User, Account, GuestViewer}
  alias Wishlists.Email.EmailService

  def register_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(Map.put(attrs, "locale", "ru"))
    |> Ecto.Changeset.cast_assoc(:account, with: &Account.changeset/2)
    |> Repo.insert()
    |> case do
      {:ok, user} = result ->
        EmailService.send_welcome_email(user)
        |> EmailService.handle_delivery()

        result

      error ->
        error
    end
  end

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  def get_user_by_telegram_id(nil), do: nil

  def get_user_by_telegram_id(telegram_id) when is_integer(telegram_id) do
    Repo.get_by(User, telegram_id: telegram_id)
  end

  def upsert_telegram_user(attrs) when is_map(attrs) do
    with {:ok, telegram_id} <- fetch_telegram_id(attrs) do
      normalized_attrs = put_telegram_id(attrs, telegram_id)

      Repo.transaction(fn ->
        case insert_or_update_telegram_user(normalized_attrs, telegram_id) do
          {:ok, user} ->
            case ensure_account_for_user(user, normalized_attrs) do
              {:ok, user_with_account} -> user_with_account
              {:error, changeset} -> Repo.rollback(changeset)
            end

          {:error, changeset} ->
            Repo.rollback(changeset)
        end
      end)
      |> case do
        {:ok, user} -> {:ok, user}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  def get_user!(id), do: Repo.get!(User, id)
  def get_user(id), do: Repo.get(User, id)

  def authenticate_user(email, password) when is_binary(email) and is_binary(password) do
    user = get_user_by_email(email)

    cond do
      user && valid_password?(user, password) ->
        {:ok, user}

      user ->
        {:error, :invalid_password}

      true ->
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}
    end
  end

  def create_guest_viewer(attrs \\ %{}) do
    %GuestViewer{}
    |> GuestViewer.changeset(attrs)
    |> Repo.insert()
  end

  def get_guest_viewer_by_token(nil), do: nil

  def get_guest_viewer_by_token(token) do
    Repo.get_by(GuestViewer, viewer_token: token)
  end

  def get_guest_viewer!(id), do: Repo.get!(GuestViewer, id)

  def generate_reset_password_token(email) when is_binary(email) do
    case get_user_by_email(email) do
      nil ->
        {:error, :not_found}

      user ->
        token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
        now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

        user
        |> Ecto.Changeset.change(%{
          reset_password_token: token,
          reset_password_sent_at: now
        })
        |> Repo.update()
        |> case do
          {:ok, user} ->
            EmailService.send_reset_password_email(user)
            |> EmailService.handle_delivery()

            {:ok, user}

          error ->
            error
        end
    end
  end

  def reset_password(token, new_password) do
    case get_user_by_reset_password_token(token) do
      nil ->
        {:error, :invalid_token}

      user ->
        if reset_password_token_expired?(user) do
          {:error, :token_expired}
        else
          user
          |> User.reset_password_changeset(%{password: new_password})
          |> Repo.update()
        end
    end
  end

  def update_user_locale(user, locale) when locale in ["en", "ru"] do
    user
    |> User.update_locale_changeset(%{locale: locale})
    |> Repo.update()
  end

  def update_user_locale(_user, _locale), do: {:error, "Invalid locale"}

  def get_user_locale(user) do
    user.locale || "ru"
  end

  @doc """
  Updates notification preferences for a user.
  """
  def update_user_notification_preferences(user, attrs) do
    user
    |> User.notification_preferences_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Generates an unsubscribe token for a user.
  The token includes the user ID and a timestamp, encrypted and signed.
  """
  def generate_unsubscribe_token(user) do
    Phoenix.Token.sign(
      WishlistsWeb.Endpoint,
      "user_unsubscribe",
      user.id,
      max_age: 86400 * 365
    )
  end

  @doc """
  Verifies an unsubscribe token and returns the associated user.
  """
  def verify_unsubscribe_token(token) do
    case Phoenix.Token.verify(
           WishlistsWeb.Endpoint,
           "user_unsubscribe",
           token,
           max_age: 86400 * 365
         ) do
      {:ok, user_id} ->
        case get_user(user_id) do
          nil -> {:error, :user_not_found}
          user -> {:ok, user}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp valid_password?(%User{hashed_password: hashed_password}, password)
       when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  defp valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  defp get_user_by_reset_password_token(token) do
    Repo.get_by(User, reset_password_token: token)
  end

  defp reset_password_token_expired?(user) do
    hours_ago = NaiveDateTime.add(NaiveDateTime.utc_now(), -24, :hour)
    NaiveDateTime.compare(user.reset_password_sent_at, hours_ago) == :lt
  end

  defp fetch_telegram_id(attrs) do
    attrs
    |> fetch_attr(:telegram_id)
    |> normalize_telegram_id()
    |> case do
      nil -> {:error, :invalid_telegram_id}
      id -> {:ok, id}
    end
  end

  defp normalize_telegram_id(nil), do: nil

  defp normalize_telegram_id(id) when is_integer(id), do: id

  defp normalize_telegram_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {value, ""} -> value
      {_value, _remainder} -> nil
      :error -> nil
    end
  end

  defp insert_or_update_telegram_user(attrs, telegram_id) do
    case get_user_by_telegram_id(telegram_id) do
      nil ->
        %User{}
        |> User.telegram_changeset(attrs)
        |> Repo.insert()

      %User{} = user ->
        user
        |> User.telegram_changeset(attrs)
        |> Repo.update()
    end
  end

  defp ensure_account_for_user(user, attrs) do
    user = Repo.preload(user, :account)

    case user.account do
      nil ->
        username =
          attrs
          |> fetch_attr(:telegram_username)
          |> build_account_username(user.telegram_id)

        %Account{}
        |> Account.changeset(%{username: username, user_id: user.id})
        |> Repo.insert()
        |> case do
          {:ok, _account} -> {:ok, Repo.preload(user, :account)}
          {:error, changeset} -> {:error, changeset}
        end

      _account ->
        {:ok, user}
    end
  end

  defp build_account_username(nil, telegram_id), do: "tg_#{telegram_id}"
  defp build_account_username("", telegram_id), do: "tg_#{telegram_id}"

  defp build_account_username(username, telegram_id) do
    username
    |> normalize_username()
    |> ensure_username_length(telegram_id)
  end

  defp normalize_username(nil), do: ""

  defp normalize_username(username) do
    username
    |> to_string()
    |> String.replace(~r/[^a-zA-Z0-9_]/, "")
    |> String.downcase()
  end

  defp ensure_username_length("", telegram_id), do: "tg_#{telegram_id}"

  defp ensure_username_length(username, telegram_id) do
    trimmed = String.slice(username, 0, 20)

    if String.length(trimmed) < 3 do
      "tg_#{telegram_id}"
    else
      trimmed
    end
  end

  defp fetch_attr(attrs, key) do
    Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))
  end

  defp put_telegram_id(attrs, telegram_id) do
    attrs
    |> Map.put(:telegram_id, telegram_id)
    |> Map.put("telegram_id", telegram_id)
  end
end
