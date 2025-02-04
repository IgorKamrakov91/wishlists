defmodule Wishlists.Folders do
  import Ecto.Query
  alias Wishlists.Repo
  alias Wishlists.Folders.{Folder, SharedFolder}

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

  def get_folder_card_count(folder_id) do
    from(fc in "folder_cards",
      where: fc.folder_id == ^folder_id,
      select: count(fc.id)
    )
    |> Wishlists.Repo.one()
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

  def create_shared_folder(folder_id) do
    %SharedFolder{}
    |> SharedFolder.changeset(%{folder_id: folder_id})
    |> Repo.insert()
  end

  def get_shared_folder_by_token(nil), do: nil

  def get_shared_folder_by_token(token) do
    Repo.get_by(SharedFolder, share_token: token)
  end

  def get_shared_folder_by_folder_id(folder_id) do
    Repo.get_by(SharedFolder, folder_id: folder_id)
  end

  def delete_shared_folder(%SharedFolder{} = shared_folder) do
    Repo.delete(shared_folder)
  end

  # Можно добавить функцию для проверки срока действия
  def get_valid_shared_folder_by_token(token) do
    now = DateTime.utc_now()

    SharedFolder
    |> Repo.get_by(share_token: token)
    |> case do
      %SharedFolder{expires_at: nil} = shared_folder ->
        shared_folder

      %SharedFolder{expires_at: expires_at} = shared_folder ->
        if DateTime.compare(expires_at, now) == :gt, do: shared_folder, else: nil

      nil ->
        nil
    end
  end
end
