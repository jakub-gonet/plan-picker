defmodule PlanPicker.Class do
  use PlanPicker.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias PlanPicker.{Accounts, Class, ClassUser, Repo, Subject, PointsAssignment, Teacher, Term}

  schema "classes" do
    field :type, :string
    field :group_number, :integer
    belongs_to :teacher, Teacher
    belongs_to :subject, Subject

    many_to_many :users, Accounts.User,
      join_through: ClassUser,
      on_replace: :delete

    has_many :points_assignments, PointsAssignment
    has_many :terms, Term

    timestamps()
  end

  def create_class!(class_attrs, %Subject{} = subject, %Teacher{} = teacher) do
    %Class{}
    |> changeset(class_attrs)
    |> put_assoc(:subject, subject)
    |> put_assoc(:teacher, teacher)
    |> Repo.insert!()
  end

  def get_class!(class_id, opts \\ [preload: [:teacher, :users, :terms]]) do
    PlanPicker.Class
    |> Repo.get!(class_id)
    |> Repo.preload(opts[:preload])
  end

  def assign_users_to_class!(class, users) do
    class = Repo.preload(class, :users)

    class
    |> change()
    |> put_assoc(:users, Enum.uniq(users ++ class.users))
    |> Repo.update!()
  end

  def remove_user_from_class!(class, user) do
    class = Repo.preload(class, :users)

    class
    |> change()
    |> put_assoc(:users, List.delete(class.users, user))
    |> Repo.update!()
  end

  def assign_points!(class, user, points) do
    case Repo.get_by(PointsAssignment, class_id: class.id, user_id: user.id) do
      nil -> %PointsAssignment{class_id: class.id, user_id: user.id}
      points_assignment -> points_assignment
    end
    |> PointsAssignment.changeset(%{points: points})
    |> Repo.insert_or_update!()
  end

  def get_points(class, user) do
    case Repo.get_by(PointsAssignment, class_id: class.id, user_id: user.id) do
      nil -> nil
      points_assignment -> points_assignment.points
    end
  end

  @doc false
  def changeset(class, attrs) do
    class
    |> cast(attrs, [:type, :group_number])
    |> validate_required([:type])
  end
end
