# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :plan_picker,
  ecto_repos: [PlanPicker.Repo]

config :plan_picker, PlanPicker.Repo, migration_primary_key: [type: :binary_id]
config :plan_picker, PlanPicker.Repo, migration_timestamps: [type: :utc_datetime]
config :plan_picker, PlanPicker.Repo, migration_foreign_key: [type: :binary_id]

# Configures the endpoint
config :plan_picker, PlanPickerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Ia195ujePV9JmEhkuSSqg1AaRVCWireKBH8o1Do/XxQ6OAYRueKgiGvISb50nDfM",
  render_errors: [view: PlanPickerWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: PlanPicker.PubSub,
  live_view: [signing_salt: "lq+mQYKs"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
