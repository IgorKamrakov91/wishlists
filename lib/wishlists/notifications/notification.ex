defmodule Wishlists.Notifications.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notifications" do
    belongs_to :user, Wishlists.Accounts.User
    field :type, :string
    field :title, :string
    field :message, :string
    field :read_at, :utc_datetime
    field :data, :map, default: %{}

    timestamps()
  end

  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:user_id, :type, :title, :message, :read_at, :data])
    |> validate_required([:user_id, :type, :title])
  end
end
