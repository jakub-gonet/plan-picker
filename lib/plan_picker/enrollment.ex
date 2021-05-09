defmodule PlanPicker.Enrollment do
  use PlanPicker.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  import Ecto, only: [assoc: 2]

  schema "enrollments" do
    field :name, :string
    field :state, Ecto.Enum, values: [:closed, :opened, :finished]

    many_to_many :users, PlanPicker.Accounts.User, join_through: "enrollments_users"
    has_many :subjects, PlanPicker.Subject

    timestamps()
  end

  @doc """
    Gets all enrollments a user is assigned to.
  """
  def get_enrollments_for_user(user) do
    query = from e in PlanPicker.Enrollment,
      join: u in assoc(e, :users),
      where: u.id == ^user.id,
      select: e
    PlanPicker.Repo.all(query)
  end

  @doc """
    Creates an association for Enrollment.users between enrollment and user.
  """
  def assign_user_to_enrollment(enrollment, user) do
    # fetch enrollment with associations
    enrollment = PlanPicker.Enrollment
    |> PlanPicker.Repo.get!(enrollment.id)
    |> PlanPicker.Repo.preload(:users)

    enrollment
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:users, [user | enrollment.users])
    |> PlanPicker.Repo.update!()
  end

  @doc false
  def changeset(enrollments, attrs) do
    enrollments
    |> cast(attrs, [:name, :state])
    |> validate_required([:name, :state])
  end
end
