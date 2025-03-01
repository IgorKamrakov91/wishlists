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
  end
end
