defmodule Wishlists.Folders.SharedFolder do
  use Ecto.Schema
  import Ecto.Changeset
  alias Wishlists.Utils.Slugify

  schema "shared_folders" do
    field :share_token, :string
    field :share_slug, :string
    field :expires_at, :utc_datetime
    belongs_to :folder, Wishlists.Folders.Folder

    timestamps()
  end

  def changeset(shared_folder, attrs) do
    shared_folder
    |> cast(attrs, [:folder_id, :share_token, :share_slug])
    |> validate_required([:folder_id])
    |> unique_constraint(:share_token)
    |> unique_constraint(:share_slug)
    |> generate_share_token()
    |> generate_share_slug()
  end

  defp generate_share_token(changeset) do
    case get_field(changeset, :share_token) do
      nil -> put_change(changeset, :share_token, Ecto.UUID.generate())
      _token -> changeset
    end
  end

  defp generate_share_slug(changeset) do
    case get_field(changeset, :share_slug) do
      nil ->
        folder_id = get_field(changeset, :folder_id)
        folder = Wishlists.Folders.get_folder!(folder_id)
        slug = generate_unique_slug(folder.name)
        put_change(changeset, :share_slug, slug)

      _slug ->
        changeset
    end
  end

  defp generate_unique_slug(name) do
    base_slug = Slugify.slugify(name)
    random_string = generate_random_string(5)
    "#{base_slug}-#{random_string}"
  end

  defp generate_random_string(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.encode32(case: :lower, padding: false)
    |> binary_part(0, length)
  end
end
