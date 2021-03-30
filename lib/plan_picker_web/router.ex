defmodule PlanPickerWeb.Router do
  use PlanPickerWeb, :router

  import PlanPickerWeb.PasswordAuthAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_password_auth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PlanPickerWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", PlanPickerWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: PlanPickerWeb.Telemetry, ecto_repos: [PlanPicker.Repo]
    end
  end

  ## Authentication routes

  scope "/", PlanPickerWeb do
    pipe_through [:browser, :redirect_if_password_auth_is_authenticated]

    get "/password_auth/register", PasswordAuthRegistrationController, :new
    post "/password_auth/register", PasswordAuthRegistrationController, :create
    get "/password_auth/log_in", PasswordAuthSessionController, :new
    post "/password_auth/log_in", PasswordAuthSessionController, :create
    get "/password_auth/reset_password", PasswordAuthResetPasswordController, :new
    post "/password_auth/reset_password", PasswordAuthResetPasswordController, :create
    get "/password_auth/reset_password/:token", PasswordAuthResetPasswordController, :edit
    put "/password_auth/reset_password/:token", PasswordAuthResetPasswordController, :update
  end

  scope "/", PlanPickerWeb do
    pipe_through [:browser, :require_authenticated_password_auth]

    get "/password_auth/settings", PasswordAuthSettingsController, :edit
    put "/password_auth/settings", PasswordAuthSettingsController, :update
    get "/password_auth/settings/confirm_email/:token", PasswordAuthSettingsController, :confirm_email
  end

  scope "/", PlanPickerWeb do
    pipe_through [:browser]

    delete "/password_auth/log_out", PasswordAuthSessionController, :delete
    get "/password_auth/confirm", PasswordAuthConfirmationController, :new
    post "/password_auth/confirm", PasswordAuthConfirmationController, :create
    get "/password_auth/confirm/:token", PasswordAuthConfirmationController, :confirm
  end
end
