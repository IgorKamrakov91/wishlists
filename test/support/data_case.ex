defmodule Wishlists.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use Wishlists.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Wishlists.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Wishlists.DataCase
    end
  end

  setup tags do
    Wishlists.DataCase.setup_sandbox(tags)
    :ok
  end

  @doc """
  Sets up the sandbox based on the test tags.
  """
  def setup_sandbox(tags) do
    Application.ensure_all_started(:wishlists)

    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Wishlists.Repo, shared: not tags[:async])

    on_exit(fn ->
      Ecto.Adapters.SQL.Sandbox.stop_owner(pid)
      Application.stop(:wishlists)
    end)
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: "test#{System.unique_integer()}@example.com",
        password: "password123"
      })
      |> Wishlists.Accounts.register_user()

    user
  end

  @doc """
  Создает гостевого пользователя с базовыми атрибутами для тестов.
  """
  def guest_viewer_fixture(attrs \\ %{}) do
    {:ok, guest_viewer} =
      attrs
      |> Enum.into(%{
        name: "Guest #{System.unique_integer()}"
      })
      |> Wishlists.Accounts.create_guest_viewer()

    guest_viewer
  end

  @doc """
  Создает аккаунт с базовыми атрибутами для тестов.
  """
  def account_fixture(attrs \\ %{}) do
    user = attrs[:user] || user_fixture()

    {:ok, account} =
      attrs
      |> Enum.into(%{
        username: "user#{System.unique_integer()}",
        user_id: user.id
      })
      |> Wishlists.Accounts.register_user()

    account
  end
end
