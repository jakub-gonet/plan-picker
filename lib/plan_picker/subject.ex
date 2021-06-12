defmodule PlanPicker.Subject do
  use PlanPicker.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
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

  def get_subject_in_enrollment!(enrollment, subject_id, opts \\ [preload: [classes: [:terms, :teacher, :users]]]) do
    query = from e in PlanPicker.Enrollment,
      join: s in assoc(e, :subjects),
      where: e.id == ^enrollment.id and s.id == ^subject_id,
      select: s

    query
    |> Repo.one!()
    |> Repo.preload(opts[:preload])
  end

  @doc false
  def changeset(subject, attrs) do
    subject
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
