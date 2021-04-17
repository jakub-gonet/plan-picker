defmodule PlanPicker.PointsAssigments do
  use Ecto.Schema
  import Ecto.Changeset

  schema "points_assignments" do
    field :points, :integer
    belongs_to :user, PlanPicker.Accounts.User
    belongs_to :term, PlanPicker.Term
    timestamps()
  end

  @doc false
  def changeset(points_assigments, attrs) do
    points_assigments
    |> cast(attrs, [:points])
    |> validate_required([:points])
  end
end
