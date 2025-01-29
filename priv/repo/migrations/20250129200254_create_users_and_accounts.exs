defmodule Wishlists.Repo.Migrations.CreateUsersAndAccounts do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :hashed_password, :string, null: false

      timestamps()
    end

    create unique_index(:users, [:email])

    create table(:accounts) do
      add :username, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:accounts, [:username])
    create index(:accounts, [:user_id])
  end
end
