defmodule Wishlists.Folders.FollowedFolder do
  use Ecto.Schema
  import Ecto.Changeset

  schema "followed_folders" do
    belongs_to :user, Wishlists.Accounts.User
    belongs_to :folder, Wishlists.Folders.Folder

    timestamps()
  end

  def changeset(followed_folder, attrs) do
    followed_folder
    |> cast(attrs, [:user_id, :folder_id])
    |> validate_required([:user_id, :folder_id])
    |> unique_constraint([:user_id, :folder_id])
  end
end
