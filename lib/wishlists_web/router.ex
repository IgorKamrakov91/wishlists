defmodule WishlistsWeb.Router do
  use WishlistsWeb, :router
  import Plug.Conn
  import Phoenix.Controller

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WishlistsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :require_authenticated_user do
    plug :ensure_authenticated
  end

  # Public routes
  scope "/", WishlistsWeb do
    pipe_through :browser

    live "/", PageLive, :home
    post "/login", UserSessionController, :create
    live "/dashboard", DashboardLive, :home
    delete "/logout", UserSessionController, :delete
  end

  # Protected routes (require authentication)
  scope "/", WishlistsWeb do
    pipe_through [:browser, :require_authenticated_user]


  end

  # Other scopes may use custom stacks.
  # scope "/api", WishlistsWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:wishlists, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: WishlistsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  defp ensure_authenticated(conn, _opts) do
    if get_session(conn, :user_id) do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> redirect(to: "/")
      |> halt()
    end
  end

  defp fetch_current_user(conn, _opts) do
    if user_id = get_session(conn, :user_id) do
      assign(conn, :current_user, Wishlists.Accounts.get_user!(user_id))
    else
      assign(conn, :current_user, nil)
    end
  end
end
