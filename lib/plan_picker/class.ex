defmodule PlanPicker.Class do
  use PlanPicker.Schema
  import Ecto.Changeset
  alias PlanPicker.{Repo, Subject, Teacher}

  schema "classes" do
    field :type, :string
    field :group_number, :integer
    belongs_to :teacher, PlanPicker.Teacher
    belongs_to :subject, PlanPicker.Subject

    many_to_many :users, PlanPicker.Accounts.User, join_through: "classes_users"
    has_many :points_assignments, PlanPicker.PointsAssigment
    has_many :terms, PlanPicker.Term

    timestamps()
  end

  def create_class!(class_attrs, %Subject{} = subject, %Teacher{} = teacher) do
    %PlanPicker.Class{}
    |> changeset(class_attrs)
    |> put_assoc(:subject, subject)
    |> put_assoc(:teacher, teacher)
    |> Repo.insert!()
  end

  @doc false
  def changeset(class, attrs) do
    class
    |> cast(attrs, [:type, :group_number])
    |> validate_required([:type])
  end
end
