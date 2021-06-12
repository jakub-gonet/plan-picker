defmodule PlanPickerWeb.Router do
  use PlanPickerWeb, :router

  import PlanPickerWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :is_moderator do
    plug :require_authenticated_user
    plug :require_role, :moderator
  end

  pipeline :is_admin do
    plug :require_authenticated_user
    plug :require_role, :admin
  end

  scope "/", PlanPickerWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  # Enables LiveDashboard only for development
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: PlanPickerWeb.Telemetry, ecto_repos: [PlanPicker.Repo]
    end
  end

  ## Authentication routes
  scope "/", PlanPickerWeb.Accounts do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  ## Session management routes
  scope "/", PlanPickerWeb.Accounts do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :confirm
  end

  ## User settings routes
  scope "/", PlanPickerWeb.Accounts do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
  end

  scope "/", PlanPickerWeb do
    pipe_through [:browser, :require_authenticated_user]
    get "/enrollments/:id/show", EnrollmentController, :show
  end

  # moderator or admin routes
  scope "/manage/", PlanPickerWeb do
    pipe_through [:browser, :is_moderator]

    get "/enrollments/", EnrollmentManagementController, :index
    get "/enrollments/:id/show", EnrollmentManagementController, :show
    get "/enrollments/:id/edit", EnrollmentManagementController, :edit
    put "/enrollments/", EnrollmentManagementController, :update
  end

  # admin only routes
  scope "/manage/", PlanPickerWeb do
    pipe_through [:browser, :is_admin]

    get "/enrollments/new", EnrollmentManagementController, :new
    post "/enrollments/", EnrollmentManagementController, :create
    delete "/enrollments/:id", EnrollmentManagementController, :delete

    get "/users/", UserController, :index
  end
end
