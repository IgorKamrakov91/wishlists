defmodule Wishlists.Repo do
  use Ecto.Repo,
    otp_app: :wishlists,
    adapter: Ecto.Adapters.Postgres
end
