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
    |> maybe_put_viewer_token()
  end

  defp maybe_put_viewer_token(changeset) do
    case get_field(changeset, :viewer_token) do
      nil -> put_change(changeset, :viewer_token, generate_viewer_token())
      _token -> changeset
    end
  end

  defp generate_viewer_token do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end
end
