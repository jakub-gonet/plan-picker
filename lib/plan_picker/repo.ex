defmodule PlanPicker.Repo do
  use Ecto.Repo,
    otp_app: :plan_picker,
    adapter: Ecto.Adapters.Postgres
end
