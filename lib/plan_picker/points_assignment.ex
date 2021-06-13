defmodule PlanPicker.PointsAssignment do
  use PlanPicker.Schema
  import Ecto.Changeset
  alias PlanPicker.Repo

  schema "points_assignments" do
    field :points, :integer
    belongs_to :user, PlanPicker.Accounts.User
    belongs_to :class, PlanPicker.Class
    timestamps()
  end

  def assign_points_to!(points_assignment, points) when points >= 0 do
    points_assignment
    |> Ecto.Changeset.put_change(:points, points)
    |> Repo.update!()
  end

  @doc false
  def changeset(points_assigment, attrs) do
    points_assigment
    |> cast(attrs, [:points, :user_id, :class_id])
    |> validate_required([:points, :user_id, :class_id])
  end
end
