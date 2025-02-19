defmodule Wishlists.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true
    field :hashed_password, :string
    field :confirmed_at, :naive_datetime
    field :reset_password_token, :string
    field :reset_password_sent_at, :naive_datetime

    has_one :account, Wishlists.Accounts.Account

    timestamps()
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password], message: "is required")
    |> validate_email()
    |> validate_password()
    |> hash_password()
    |> put_account_username()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160, message: "must be at most 160 characters")
    |> unsafe_validate_unique(:email, Wishlists.Repo, message: "is already taken")
    |> unique_constraint(:email, message: "is already taken")
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, message: "must be at least 8 characters")
  end

  defp hash_password(changeset) do
    if password = get_change(changeset, :password) do
      changeset
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  def reset_password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_password()
    |> hash_password()
    |> put_change(:reset_password_token, nil)
    |> put_change(:reset_password_sent_at, nil)
  end

  defp put_account_username(changeset) do
    if email = get_change(changeset, :email) do
      username = email |> String.split("@") |> hd() |> ensure_unique_username()
      put_assoc(changeset, :account, %{username: username})
    else
      changeset
    end
  end

  defp ensure_unique_username(base_username) do
    base_username
  end
end
