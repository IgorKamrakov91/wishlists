defmodule Wishlists.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true
    field :hashed_password, :string
    field :confirmed_at, :naive_datetime

    has_one :account, Wishlists.Accounts.Account

    timestamps()
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_email()
    |> validate_password()
    |> put_account_username()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, Wishlists.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 72, message: "must be between 8 and 72 characters")
    |> validate_format(:password, ~r/[a-z]/,
      message: "must include at least one lowercase letter"
    )
    |> validate_format(:password, ~r/[A-Z]/,
      message: "must include at least one uppercase letter"
    )
    |> validate_format(:password, ~r/[!@#$%^&*(),.?":{}|<>]/,
      message: "must include at least one special character (!@#$%^&*(),.?\":{}|<>)"
    )
    |> prepare_changes(&hash_password/1)
  end

  defp hash_password(changeset) do
    password = get_change(changeset, :password)

    changeset
    |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
    |> delete_change(:password)
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
    # Add logic to ensure username uniqueness by adding number suffix if needed
    base_username
  end
end
