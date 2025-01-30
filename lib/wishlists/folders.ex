defmodule Wishlists.Folders do
  import Ecto.Query
  alias Wishlists.Repo
  alias Wishlists.Folders.Folder

  def list_user_folders(user_id) do
    Folder
    |> where(user_id: ^user_id)
    |> order_by([f], f.inserted_at)
    |> Repo.all()
  end

  def create_folder(attrs \\ %{}) do
    %Folder{}
    |> Folder.changeset(attrs)
    |> Repo.insert()
  end

  def get_folder!(id), do: Repo.get!(Folder, id)

  def get_user_folder!(user_id, folder_id) do
    Folder
    |> where(user_id: ^user_id, id: ^folder_id)
    |> Repo.one!()
  end

  def update_folder(%Folder{} = folder, attrs) do
    folder
    |> Folder.changeset(attrs)
    |> Repo.update()
  end

  def change_folder(%Folder{} = folder, attrs \\ %{}) do
    Folder.changeset(folder, attrs)
  end

  def delete_folder(%Folder{} = folder) do
    Repo.delete(folder)
  end
end
