defmodule PlanPicker.Subject do
  use PlanPicker.Schema
  import Ecto.Changeset
  alias PlanPicker.Repo

  schema "subjects" do
    field :name, :string
    has_many :classes, PlanPicker.Class

    belongs_to :enrollment, PlanPicker.Enrollment

    timestamps()
  end

  def create_subject!(subject_params, enrollment) do
    %PlanPicker.Subject{}
    |> changeset(subject_params)
    |> put_assoc(:classes, [])
    |> put_assoc(:enrollment, enrollment)
    |> Repo.insert!()
  end

  @doc false
  def changeset(subject, attrs) do
    subject
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
