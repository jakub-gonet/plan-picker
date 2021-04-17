defmodule PlanPicker.Term do
  use Ecto.Schema
  import Ecto.Changeset

  schema "terms" do
    field :interval, Timestamp.Range
    field :location, :string
    field :week_type, :string
    belongs_to :class, PlanPicker.Class
    has_many :points_assignments, PlanPicker.PointsAssigments

    timestamps()
  end

  @doc false
  def changeset(term, attrs) do
    term
    |> cast(attrs, [:interval, :location, :week_type])
    |> validate_required([:interval, :location, :week_type])
  end
end
