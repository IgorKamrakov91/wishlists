defmodule Wishlists.Accounts.User do
  use Ecto.Schema
  use Gettext, backend: WishlistsWeb.Gettext
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true
    field :hashed_password, :string
    field :confirmed_at, :naive_datetime
    field :reset_password_token, :string
    field :reset_password_sent_at, :naive_datetime
    field :locale, :string, default: "ru"

    field :notification_preferences, :map,
      default: %{
        "cleanup_notifications" => true,
        "reservation_notifications" => true
      }

    has_one :account, Wishlists.Accounts.Account

    timestamps()
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password], message: "is required")
    |> validate_inclusion(:locale, ["en", "ru"])
    |> validate_email()
    |> validate_password()
    |> hash_password()
    |> put_account_username()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/,
      message: gettext("must have the @ sign and no spaces")
    )
    |> validate_length(:email, max: 160, message: gettext("must be at most 160 characters"))
    |> unsafe_validate_unique(:email, Wishlists.Repo, message: gettext("is already taken"))
    |> unique_constraint(:email, message: gettext("is already taken"))
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, message: gettext("must be at least 8 characters"))
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

  def update_locale_changeset(user, attrs) do
    user
    |> cast(attrs, [:locale])
    |> validate_required([:locale])
    |> validate_inclusion(:locale, ["en", "ru"])
  end

  @doc """
  Changeset for updating notification preferences.
  """
  def notification_preferences_changeset(user, attrs) do
    user
    |> cast(attrs, [:notification_preferences])
    |> validate_required([:notification_preferences])
    |> validate_notification_preferences()
  end

  defp validate_notification_preferences(changeset) do
    validate_change(
      changeset,
      :notification_preferences,
      fn :notification_preferences, preferences ->
        valid_keys = ["cleanup_notifications", "reservation_notifications"]

        if Enum.all?(Map.keys(preferences), &(&1 in valid_keys)) do
          []
        else
          [notification_preferences: "contains invalid notification types"]
        end
      end
    )
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
