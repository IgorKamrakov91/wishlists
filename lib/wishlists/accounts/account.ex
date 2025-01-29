defmodule Wishlists.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts" do
    field :username, :string
    belongs_to :user, Wishlists.Accounts.User

    timestamps()
  end

  def changeset(account, attrs) do
    account
    |> cast(attrs, [:username])
    |> validate_required([:username])
    |> validate_length(:username, min: 3, max: 20)
    |> unique_constraint(:username)
  end
end
