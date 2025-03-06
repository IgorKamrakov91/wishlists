defmodule Wishlists.Accounts.Account do
  use Ecto.Schema
  use Gettext, backend: WishlistsWeb.Gettext
  import Ecto.Changeset

  schema "accounts" do
    field :username, :string
    belongs_to :user, Wishlists.Accounts.User

    timestamps()
  end

  def changeset(account, attrs) do
    account
    |> cast(attrs, [:username, :user_id])
    |> validate_required([:username])
    |> validate_length(:username, min: 3, max: 20)
    |> unique_constraint(:username,
      name: "accounts_username_index",
      message: gettext("Username already taken")
    )
  end
end
