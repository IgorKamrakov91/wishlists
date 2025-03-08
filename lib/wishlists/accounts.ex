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

  def get_user!(id), do: Repo.get!(User, id)
  def get_user(id), do: Repo.get(User, id)

  def authenticate_user(email, password) when is_binary(email) and is_binary(password) do
    user = get_user_by_email(email)

    cond do
      user && valid_password?(user, password) ->
        IO.puts("Authentication successful for user: #{user.email}")
        {:ok, user}

      user ->
        IO.puts("Invalid password for user: #{user.email}")
        {:error, :invalid_password}

      true ->
        IO.puts("No user found with email: #{email}")
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
    user.locale || "en"
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
end
