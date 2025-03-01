defmodule Wishlists.Accounts.GuardianTest do
  use Wishlists.DataCase

  alias Wishlists.Accounts.{Guardian, User}

  describe "subject_for_token/2" do
    test "returns ok tuple with user id for valid user" do
      user = %User{id: 123}
      assert {:ok, "123"} = Guardian.subject_for_token(user, %{})
    end

    test "returns error for invalid resource" do
      assert {:error, :invalid_resource} = Guardian.subject_for_token(%{}, %{})
    end
  end

  describe "resource_from_claims/1" do
    test "returns error for invalid claims" do
      assert {:error, :invalid_claims} = Guardian.resource_from_claims(%{})
    end

    # Note: More comprehensive tests for resource_from_claims would require
    # setting up test data in the database and mocking Accounts.get_user/1
  end
end
