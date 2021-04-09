defmodule PlanPicker.Class do
  use Ecto.Schema
  import Ecto.Changeset

  schema "classes" do
    field :type, :string
    belongs_to :teacher, PlanPicker.Teacher
    belongs_to :subject, PlanPicker.Subject

    timestamps()
  end

  @doc false
  def changeset(class, attrs) do
    class
    |> cast(attrs, [:type])
    |> validate_required([:type])
  end
end
