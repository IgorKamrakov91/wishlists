defmodule Wishlists.Folders do
  import Ecto.Query
  alias Wishlists.Repo
  alias Wishlists.Folders.{Folder, FollowedFolder, SharedFolder}
  alias Wishlists.Cards.Card
  alias Wishlists.Cards

  def list_user_folders(user_id) do
    Folder
    |> where(user_id: ^user_id)
    |> order_by([f], f.inserted_at)
    |> preload(user: [:account])
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
    Repo.transaction(fn ->
      folder_cards = Cards.list_folder_cards(folder.id)

      {reserved, _unreserved} = Enum.split_with(folder_cards, & &1.reservation)

      reserved_card_ids = Enum.map(reserved, & &1.card_id)

      if length(reserved_card_ids) > 0 do
        from(c in Card, where: c.id in ^reserved_card_ids)
        |> Repo.delete_all()
      end

      Repo.delete(folder)
    end)
  end

  def create_shared_folder(folder_id) do
    %SharedFolder{}
    |> SharedFolder.changeset(%{folder_id: folder_id})
    |> Repo.insert()
  end

  def get_shared_folder_by_token(token) when is_binary(token) do
    Repo.get_by(SharedFolder, share_token: token)
  end

  def get_shared_folder_by_token(_), do: nil

  def get_shared_folder_by_folder_id(folder_id) do
    Repo.get_by(SharedFolder, folder_id: folder_id)
  end

  def get_shared_folder_by_slug(slug) when is_binary(slug) do
    Repo.get_by(SharedFolder, share_slug: slug)
  end

  def get_shared_folder_by_slug(_), do: nil

  def delete_shared_folder(%SharedFolder{} = shared_folder) do
    Repo.delete(shared_folder)
  end

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

  def follow_folder(user_id, folder_id) do
    %FollowedFolder{}
    |> FollowedFolder.changeset(%{user_id: user_id, folder_id: folder_id})
    |> Repo.insert(on_conflict: :nothing)
  end

  def unfollow_folder(user_id, folder_id) do
    from(f in FollowedFolder, where: f.user_id == ^user_id and f.folder_id == ^folder_id)
    |> Repo.delete_all()
  end

  def is_following?(user_id, folder_id) do
    Repo.exists?(
      from f in FollowedFolder, where: f.user_id == ^user_id and f.folder_id == ^folder_id
    )
  end

  def list_followed_folders(user_id) do
    from(f in Folder,
      join: ff in FollowedFolder,
      on: ff.folder_id == f.id,
      where: ff.user_id == ^user_id,
      preload: [user: [:account]]
    )
    |> Repo.all()
  end
end
