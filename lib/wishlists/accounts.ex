defmodule Wishlists.Accounts do
  alias Wishlists.Repo
  alias Wishlists.Accounts.{User, Account, GuestViewer}
  alias Wishlists.Email.EmailService

  def register_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
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
        # Add debug log
        IO.puts("Authentication successful for user: #{user.email}")
        {:ok, user}

      user ->
        # Add debug log
        IO.puts("Invalid password for user: #{user.email}")
        {:error, :invalid_password}

      true ->
        # Add debug log
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
