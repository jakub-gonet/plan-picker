defmodule PlanPicker.Enrollment do
  use PlanPicker.Schema
  import Ecto.Changeset

  schema "enrollments" do
    field :name, :string
    field :state, Ecto.Enum, values: [:closed, :opened, :finished]

    many_to_many :users, PlanPicker.Accounts.User, join_through: "enrollments_users"
    has_many :subjects, PlanPicker.Subject

    timestamps()
  end

  @doc false
  def changeset(enrollments, attrs) do
    enrollments
    |> cast(attrs, [:name, :state])
    |> validate_required([:name, :state])
  end
end
