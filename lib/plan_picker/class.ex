defmodule PlanPicker.Class do
  use PlanPicker.Schema
  import Ecto.Changeset
  alias PlanPicker.{Repo, Subject, Teacher}

  schema "classes" do
    field :type, :string
    field :group_number, :integer
    belongs_to :teacher, PlanPicker.Teacher
    belongs_to :subject, PlanPicker.Subject

    many_to_many :users, PlanPicker.Accounts.User,
      join_through: PlanPicker.ClassUser,
      on_replace: :delete

    has_many :points_assignments, PlanPicker.PointsAssignment
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

  @doc false
  def changeset(class, attrs) do
    class
    |> cast(attrs, [:type, :group_number])
    |> validate_required([:type])
  end
end
