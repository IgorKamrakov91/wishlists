defmodule Wishlists.Accounts.GuestViewerTest do
  use Wishlists.DataCase

  alias Wishlists.Accounts.GuestViewer

  describe "changeset/2" do
    test "requires name" do
      changeset = GuestViewer.changeset(%GuestViewer{}, %{})
      assert "can't be blank" in errors_on(changeset).name
    end

    test "generates viewer token" do
      changeset = GuestViewer.changeset(%GuestViewer{}, %{name: "Guest"})
      assert changeset.changes.viewer_token
      assert String.length(changeset.changes.viewer_token) > 0
    end

    test "keeps an existing viewer token when updating the name" do
      viewer = %GuestViewer{name: "Guest", viewer_token: "existing-token"}

      changeset = GuestViewer.changeset(viewer, %{name: "Updated guest"})

      refute Map.has_key?(changeset.changes, :viewer_token)
      assert Ecto.Changeset.get_field(changeset, :viewer_token) == "existing-token"
    end
  end
end
