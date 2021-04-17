defmodule PlanPicker.Teacher do
  use PlanPicker.Schema
  import Ecto.Changeset

  schema "teachers" do
    field :name, :string
    field :surname, :string
    has_many :classes, PlanPicker.Class

    timestamps()
  end

  @doc false
  def changeset(teacher, attrs) do
    teacher
    |> cast(attrs, [:name, :surname])
    |> validate_required([:name, :surname])
  end
end
