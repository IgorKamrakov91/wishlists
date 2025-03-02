defmodule Wishlists.Accounts.AccountTest do
  use Wishlists.DataCase

  alias Wishlists.Accounts.{Account, User}
  alias Wishlists.Accounts

  describe "changeset/2" do
    setup do
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
      changeset = Account.changeset(%Account{}, %{username: "ab"})
      assert "should be at least 3 character(s)" in errors_on(changeset).username

      long_username = String.duplicate("a", 21)
      changeset = Account.changeset(%Account{}, %{username: long_username})
      assert "should be at most 20 character(s)" in errors_on(changeset).username
    end

    test "validates username uniqueness", %{user: user} do
      {:ok, _account} = Repo.insert(%Account{username: "testuser", user_id: user.id})

      changeset = Account.changeset(%Account{}, %{username: "testuser", user_id: user.id})
      assert {:error, changeset} = Repo.insert(changeset)
      assert "Username already taken" in errors_on(changeset).username
    end
  end

  describe "user locale" do
    setup do
      {:ok, user} =
        Accounts.register_user(%{
          email: "test@example.com",
          password: "password123"
        })

      assert_received {:email, _}

      %{user: user}
    end

    test "update_user_locale/2 updates user locale", %{user: user} do
      assert {:ok, updated_user} = Accounts.update_user_locale(user, "ru")
      assert updated_user.locale == "ru"
    end

    test "update_user_locale/2 fails with invalid locale", %{user: user} do
      assert_raise FunctionClauseError, fn ->
        Accounts.update_user_locale(user, "invalid")
      end
    end

    test "get_user_locale/1 returns user locale or default", %{user: user} do
      assert Accounts.get_user_locale(user) == "en"

      {:ok, updated_user} = Accounts.update_user_locale(user, "ru")
      assert Accounts.get_user_locale(updated_user) == "ru"
    end
  end
end
