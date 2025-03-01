defmodule Wishlists.Accounts.UserTest do
  use Wishlists.DataCase

  alias Wishlists.Accounts.User

  describe "registration_changeset/2" do
    @valid_attrs %{
      email: "test@example.com",
      password: "password123"
    }

    test "creates valid changeset with valid attributes" do
      changeset = User.registration_changeset(%User{}, @valid_attrs)
      assert changeset.valid?
    end

    test "validates email format" do
      attrs = Map.put(@valid_attrs, :email, "invalid")
      changeset = User.registration_changeset(%User{}, attrs)
      assert "must have the @ sign and no spaces" in errors_on(changeset).email
    end

    test "validates password length" do
      attrs = Map.put(@valid_attrs, :password, "short")
      changeset = User.registration_changeset(%User{}, attrs)
      assert "must be at least 8 characters" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      # First create a user
      {:ok, _user} = Repo.insert(User.registration_changeset(%User{}, @valid_attrs))

      # Try to create another user with same email
      changeset = User.registration_changeset(%User{}, @valid_attrs)
      assert {:error, changeset} = Repo.insert(changeset)
      assert "is already taken" in errors_on(changeset).email
    end

    test "hashes password" do
      changeset = User.registration_changeset(%User{}, @valid_attrs)
      assert changeset.changes.hashed_password
      refute changeset.changes[:password]
    end
  end

  describe "reset_password_changeset/2" do
    test "validates and hashes new password" do
      user = %User{
        reset_password_token: "old_token",
        reset_password_sent_at: ~N[2023-01-01 00:00:00]
      }

      attrs = %{password: "newpassword123"}
      changeset = User.reset_password_changeset(user, attrs)

      assert changeset.valid?
      assert changeset.changes.hashed_password
      assert changeset.changes.reset_password_token == nil
      assert changeset.changes.reset_password_sent_at == nil
    end

    test "validates password presence" do
      changeset = User.reset_password_changeset(%User{}, %{})
      assert "can't be blank" in errors_on(changeset).password
    end

    test "validates password length" do
      changeset = User.reset_password_changeset(%User{}, %{password: "short"})
      assert "must be at least 8 characters" in errors_on(changeset).password
    end
  end

  describe "update_locale_changeset/2" do
    test "validates locale" do
      user = %User{}

      # Valid locale
      changeset = User.update_locale_changeset(user, %{locale: "en"})
      assert changeset.valid?

      # Invalid locale
      changeset = User.update_locale_changeset(user, %{locale: "invalid"})
      assert "is invalid" in errors_on(changeset).locale
    end
  end
end
