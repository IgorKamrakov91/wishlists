defmodule Wishlists.Folders.Folder do
  use Ecto.Schema
  use Gettext, backend: WishlistsWeb.Gettext
  import Ecto.Changeset

  schema "folders" do
    field :name, :string
    field :description, :string
    field :show_reserver_names, :boolean, default: false
    field :event_date, :date
    field :event_type, :string
    belongs_to :user, Wishlists.Accounts.User

    many_to_many :cards, Wishlists.Cards.Card,
      join_through: "folder_cards",
      on_delete: :delete_all

    timestamps()
  end

  def changeset(folder, attrs) do
    folder
    |> cast(attrs, [:name, :description, :user_id, :show_reserver_names, :event_date, :event_type])
    |> validate_required([:name, :user_id])
    |> validate_length(:name, min: 1, max: 50)
    |> validate_length(:description, max: 40)
    |> validate_inclusion(
      :event_type,
      ~w(birthday wedding christmas new_year valentines_day other)
    )
    |> validate_event_date()
  end

  defp validate_event_date(changeset) do
    case get_change(changeset, :event_date) do
      nil ->
        changeset

      date ->
        if Date.compare(date, Date.utc_today()) in [:gt, :eq] do
          changeset
        else
          add_error(changeset, :event_date, gettext("must be today or in the future"))
        end
    end
  end
end
