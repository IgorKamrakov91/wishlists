defmodule Wishlists.Repo.Migrations.CreateGuestViewers do
  use Ecto.Migration

  def change do
    create table(:guest_viewers) do
      add :name, :string, null: false
      add :viewer_token, :string, null: false

      timestamps()
    end

    create unique_index(:guest_viewers, [:viewer_token])
  end
end
