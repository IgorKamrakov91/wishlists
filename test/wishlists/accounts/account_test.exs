defmodule Wishlists.Accounts.AccountTest do
  use Wishlists.DataCase

  alias Wishlists.Accounts.{Account, User}

  describe "changeset/2" do
    setup do
      # Создаем пользователя для тестов
      {:ok, user} =
        %User{}
        |> User.registration_changeset(%{
          email: "test@example.com",
          password: "password123"
        })
        |> Repo.insert()

      %{user: user}
    end

    test "validates required fields" do
      changeset = Account.changeset(%Account{}, %{})
      assert "can't be blank" in errors_on(changeset).username
    end

    test "validates username length" do
      # Too short
      changeset = Account.changeset(%Account{}, %{username: "ab"})
      assert "should be at least 3 character(s)" in errors_on(changeset).username

      # Too long
      long_username = String.duplicate("a", 21)
      changeset = Account.changeset(%Account{}, %{username: long_username})
      assert "should be at most 20 character(s)" in errors_on(changeset).username
    end

    test "validates username uniqueness", %{user: user} do
      # First create an account
      {:ok, _account} = Repo.insert(%Account{username: "testuser", user_id: user.id})

      # Try to create another account with same username
      changeset = Account.changeset(%Account{}, %{username: "testuser", user_id: user.id})
      assert {:error, changeset} = Repo.insert(changeset)
      assert "Username already taken" in errors_on(changeset).username
    end
  end
end
