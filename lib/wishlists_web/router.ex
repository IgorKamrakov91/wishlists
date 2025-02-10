defmodule WishlistsWeb.Router do
  use WishlistsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WishlistsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_locale
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
    pipe_through :browser

    live "/shared/:token", SharedFolderLive.Show
    get "/set_viewer_session", ViewerSessionController, :set_session
    get "/clear_viewer_session", ViewerSessionController, :clear
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

  live_session :notifications,
    on_mount: [{WishlistsWeb.UserAuth, :ensure_authenticated}] do
    live "/notifications", NotificationLive
  end

  defp put_locale(conn, _opts) do
    locale = conn.params["locale"] || get_session(conn, :locale) || "en"
    locale = if locale in ["en", "ru"], do: locale, else: "en"

    conn
    |> put_session(:locale, locale)
  end
end
