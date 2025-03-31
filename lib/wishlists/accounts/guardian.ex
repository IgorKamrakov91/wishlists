defmodule Wishlists.Accounts.Guardian do
  use Guardian, otp_app: :wishlists

  alias Wishlists.Accounts

  def subject_for_token(%Accounts.User{} = user, _claims) do
    {:ok, to_string(user.id)}
  end

  def subject_for_token(_, _), do: {:error, :invalid_resource}

  def resource_from_claims(%{"sub" => id}) do
    case Accounts.get_user(id) do
      nil -> {:error, :resource_not_found}
      user -> {:ok, user}
    end
  end

  def resource_from_claims(_), do: {:error, :invalid_claims}

  @doc """
  Generate a token for a user with appropriate TTL based on remember_me flag.
  """
  def generate_user_token(user, remember_me \\ false) do
    encode_and_sign(
      user,
      %{},
      ttl: get_token_ttl(remember_me)
    )
  end

  defp get_token_ttl(true), do: {30, :day}
  defp get_token_ttl(_), do: {1, :day}
end
