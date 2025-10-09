defmodule AuraWeb.Router do
  use AuraWeb, :router

  import AuraWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AuraWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_auth do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :fetch_current_scope_for_user
    plug :require_authenticated_user
  end

  scope "/", AuraWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # API routes for webhook integration
  scope "/api", AuraWeb.Api do
    pipe_through :api_auth

    post "/webhooks/bom/:project_id", BOMWebhookController, :import
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:aura, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AuraWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", AuraWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{AuraWeb.UserAuth, :require_authenticated}] do
      live "/dashboard", DashboardLive.Index, :index
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
      # Permissions Management
      live "/permissions", PermissionsLive.Index, :index
      # User Management
      live "/users", UserManagementLive.Index, :index
      # Clients
      live "/clients/new", ClientLive.Form, :new
      live "/clients", ClientLive.Index, :index
      live "/clients/:id", ClientLive.Show, :show
      live "/clients/:id/edit", ClientLive.Form, :edit
      # Contact
      live "/contacts/new", ContactLive.Form, :new
      live "/contacts", ContactLive.Index, :index
      live "/contacts/:id", ContactLive.Show, :show
      live "/contacts/:id/edit", ContactLive.Form, :edit
      # Projects
      live "/projects", ProjectsLive.Index, :index
      live "/projects/new", ProjectsLive.Index, :new
      live "/projects/:id/edit", ProjectsLive.Index, :edit
      live "/projects/:id", ProjectsLive.Show, :show
      live "/projects/:id/subprojects", ProjectsLive.Show, :show
      live "/projects/:id/bom", ProjectsLive.Show, :show
      live "/projects/:id/subprojects/new", ProjectsLive.Show, :new_subproject
      live "/projects/:id/subprojects/:subproject_id/edit", ProjectsLive.Show, :edit_subproject
      live "/projects/:id/bom/new", ProjectsLive.Show, :new_bom
      live "/projects/:id/bom/:bom_id/edit", ProjectsLive.Show, :edit_bom
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", AuraWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{AuraWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
