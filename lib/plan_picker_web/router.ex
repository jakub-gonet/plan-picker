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

  scope "/", PlanPickerWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email

    get "/enrollments/", EnrollmentController, :get_enrollments_for_current_user
  end

  # moderator or admin routes
  scope "/manage/", PlanPickerWeb do
    pipe_through [:browser, :require_authenticated_user, :require_moderator_role]

    # get "/enrollments/" # index
    # get "/enrollments/:id" # edit
    # put "/enrollments/:id" # update
  end

  # admin only routes
  scope "/manage/", PlanPickerWeb do
    pipe_through [:browser, :require_authenticated_user, :require_admin_role]

    # post "/enrollments/" # create
    # delete "/enrollments/:id # delete

    # get "/users/" # index
    # get "/users/:id" # show
    # put "/users/:id" # update
    # post "/users/" # create
    # delete "/users/:id" # delete
  end

  scope "/", PlanPickerWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :confirm
  end
end
