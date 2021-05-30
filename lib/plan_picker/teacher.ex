defmodule PlanPicker.Teacher do
  use PlanPicker.Schema
  import Ecto.Changeset
  alias PlanPicker.Repo

  schema "teachers" do
    field :name, :string
    field :surname, :string
    has_many :classes, PlanPicker.Class

    timestamps()
  end

  def create_teacher(teacher_attrs) do
    %PlanPicker.Teacher{}
    |> changeset(teacher_attrs)
    |> Repo.insert!()
  end

  @doc false
  def changeset(teacher, attrs) do
    teacher
    |> cast(attrs, [:name, :surname])
    |> validate_required([:name, :surname])
  end
end
