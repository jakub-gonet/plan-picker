defmodule PlanPicker.Class do
  use PlanPicker.Schema
  import Ecto.Changeset

  schema "classes" do
    field :type, :string
    belongs_to :teacher, PlanPicker.Teacher
    belongs_to :subject, PlanPicker.Subject

    many_to_many(:users, PlanPicker.Accounts.User, join_through: "classes_users")

    has_many :points_assignments, PlanPicker.PointsAssigment

    has_many :terms, PlanPicker.Term

    timestamps()
  end

  def add_class(class_attrs, subject) do
    %PlanPicker.Class{}
    |> changeset(class_attrs)
    |> Ecto.Changeset.put_assoc(:subject, subject)
    |> PlanPicker.Repo.insert!()
  end

  def assign_teacher(class, teacher) do
    class
    |> PlanPicker.Repo.preload(:teacher)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:teacher, teacher)
    |> PlanPicker.Repo.update!()
  end

  @doc false
  def changeset(class, attrs) do
    class
    |> cast(attrs, [:type])
    |> validate_required([:type])
  end
end
