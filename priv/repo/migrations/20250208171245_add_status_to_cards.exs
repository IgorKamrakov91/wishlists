defmodule Wishlists.Repo.Migrations.AddStatusToCards do
  use Ecto.Migration

  def change do
    alter table(:cards) do
      add :status, :string, default: "approved"
      add :suggested_by_user_id, references(:users, on_delete: :nilify_all)
      add :suggested_by_guest_id, references(:guest_viewers, on_delete: :nilify_all)
    end
  end
end
