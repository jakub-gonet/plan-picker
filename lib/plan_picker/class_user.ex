defmodule PlanPicker.ClassUser do
  use PlanPicker.Schema

  schema "classes_users" do
    belongs_to :user, PlanPicker.Accounts.User
    belongs_to :class, PlanPicker.Class

    timestamps()
  end
end
