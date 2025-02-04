defmodule Wishlists.Accounts.GuestViewer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "guest_viewers" do
    field :name, :string
    field :viewer_token, :string

    timestamps()
  end

  def changeset(guest_viewer, attrs) do
    guest_viewer
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> put_change(:viewer_token, generate_viewer_token())
  end

  defp generate_viewer_token do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end
end
