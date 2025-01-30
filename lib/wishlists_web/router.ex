defmodule WishlistsWeb.Router do
  use WishlistsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WishlistsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :auth do
    plug Guardian.Plug.Pipeline,
      module: Wishlists.Accounts.Guardian,
      error_handler: WishlistsWeb.AuthErrorHandler

    plug Guardian.Plug.VerifySession
    plug Guardian.Plug.LoadResource, allow_blank: true
  end

  pipeline :ensure_auth do
    plug Guardian.Plug.EnsureAuthenticated
  end

  scope "/", WishlistsWeb do
    pipe_through [:browser, :auth]

    live "/", PageLive, :home
    get "/auth/set_session", AuthController, :set_session
    delete "/auth/sign_out", AuthController, :sign_out
  end

  scope "/", WishlistsWeb do
    pipe_through [:browser, :auth, :ensure_auth]

    live "/dashboard", DashboardLive, :home
    live "/folders/:id", FolderLive.Show, :show
  end
end
