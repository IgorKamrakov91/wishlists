defmodule Wishlists.Folders.SharedFolder do
  use Ecto.Schema
  import Ecto.Changeset

  schema "shared_folders" do
    field :share_token, :string
    field :expires_at, :utc_datetime
    belongs_to :folder, Wishlists.Folders.Folder

    timestamps()
  end

  def changeset(shared_folder, attrs) do
    shared_folder
    |> cast(attrs, [:folder_id, :expires_at])
    |> put_change(:share_token, generate_share_token())
    |> validate_required([:folder_id, :share_token])
    |> foreign_key_constraint(:folder_id)
  end

  defp generate_share_token do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end
end
