Application.ensure_all_started(:wishlists)
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Wishlists.Repo, :manual)
