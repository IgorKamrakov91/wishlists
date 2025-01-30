defmodule Wishlists.Accounts do
  alias Wishlists.Repo
  alias Wishlists.Accounts.{User, Account}

  def register_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Ecto.Changeset.cast_assoc(:account, with: &Account.changeset/2)
    |> Repo.insert()
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

  defp valid_password?(%User{hashed_password: hashed_password}, password)
       when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  defp valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end
end
