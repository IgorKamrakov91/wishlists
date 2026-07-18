defmodule Wishlists.Accounts.User do
  use Ecto.Schema
  use Gettext, backend: WishlistsWeb.Gettext
  import Ecto.Changeset

  @auth_providers ~w(email telegram)

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true
    field :hashed_password, :string
    field :confirmed_at, :naive_datetime
    field :reset_password_token, :string
    field :reset_password_sent_at, :naive_datetime
    field :locale, :string, default: "ru"
    field :telegram_id, :integer
    field :telegram_username, :string
    field :telegram_photo_url, :string
    field :auth_provider, :string, default: "email"

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
    |> put_default_auth_provider("email")
    |> validate_auth_provider()
    |> validate_email()
    |> validate_password()
    |> hash_password()
    |> put_account_username()
  end

  def telegram_changeset(user, attrs) do
    user
    |> cast(attrs, [:telegram_id, :telegram_username, :telegram_photo_url, :auth_provider])
    |> put_default_auth_provider("telegram")
    |> validate_required([:telegram_id])
    |> validate_number(:telegram_id, greater_than: 0)
    |> validate_auth_provider()
    |> unique_constraint(:telegram_id)
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

        valid_preferences? =
          Enum.all?(preferences, fn {key, value} ->
            key in valid_keys and is_boolean(value)
          end)

        if valid_preferences? do
          []
        else
          [notification_preferences: "contains invalid notification preferences"]
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

  defp put_default_auth_provider(changeset, provider) do
    case get_change(changeset, :auth_provider) || get_field(changeset, :auth_provider) do
      nil -> put_change(changeset, :auth_provider, provider)
      value when value in @auth_providers -> changeset
      _ -> put_change(changeset, :auth_provider, provider)
    end
  end

  defp validate_auth_provider(changeset) do
    validate_inclusion(changeset, :auth_provider, @auth_providers)
  end

  defp ensure_unique_username(base_username) do
    base_username
  end
end
