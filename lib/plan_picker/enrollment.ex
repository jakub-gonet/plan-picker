defmodule PlanPicker.Enrollment do
  use PlanPicker.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias PlanPicker.{Enrollment, Repo}

  schema "enrollments" do
    field :name, :string
    field :state, Ecto.Enum, values: [:closed, :opened, :finished]

    many_to_many :users, PlanPicker.Accounts.User,
      join_through: "enrollments_users",
      on_replace: :delete

    has_many :subjects, PlanPicker.Subject

    timestamps()
  end

  @doc """
    Gets all enrollments a user is assigned to.
  """
  def get_enrollments_for_user(user) do
    query =
      from e in PlanPicker.Enrollment,
        join: u in assoc(e, :users),
        where: u.id == ^user.id,
        select: e

    Repo.all(query)
  end

  def get_enrollment_by_name(name) do
    Repo.get_by(Enrollment, name: name)
  end

  @doc """
    Creates an association for Enrollment.users between enrollment and user.
  """
  def assign_user_to_enrollment(enrollment, user) do
    # fetch enrollment with associations
    enrollment = Repo.preload(enrollment, :users)

    enrollment
    |> change()
    |> put_assoc(:users, [user | enrollment.users])
    |> Repo.update!()
  end

  def assign_users_to_enrollment!(enrollment, users) do
    enrollment = Repo.preload(enrollment, :users)

    enrollment
    |> change()
    |> put_assoc(:users, Enum.uniq(users ++ enrollment.users))
    |> Repo.update!()
  end

  def unassign_users_from_enrollment!(enrollment, users) do
    enrollment = Repo.preload(enrollment, :users)

    enrollment
    |> change()
    |> put_assoc(:users, Enum.filter(enrollment.users, &(&1 not in users)))
    |> Repo.update!()
  end

  def create_enrollment(enrollment_params) do
    %PlanPicker.Enrollment{state: :closed}
    |> change()
    |> Enrollment.changeset(enrollment_params)
    |> Repo.insert!()
  end

  def get_enrollment!(enrollment_id, opts \\ %{preload: [:users, :subjects]}) do
    Enrollment
    |> Repo.get!(enrollment_id)
    |> Repo.preload(opts.preload)
  end

  def get_terms_for_enrollment(enrollment) do
    query = from e in Enrollment,
      join: subj in assoc(e, :subjects),
      join: class in assoc(subj, :classes),
      join: teacher in assoc(class, :teacher),
      join: term in assoc(class, :terms),
      where: e.id == ^enrollment.id,
      select: %{
        name: subj.name,
        type: class.type,
        group_number: class.group_number,
        teacher: teacher,
        id: term.id,
        interval: term.interval,
        location: term.location,
        week_type: term.week_type
      }

    Repo.all(query)
  end

  def get_all_enrollments do
    Repo.all(PlanPicker.Enrollment)
  end

  def update_enrollment!(enrollment, enrollment_params) do
    enrollment
    |> Enrollment.changeset(enrollment_params)
    |> Repo.update!()
  end

  def delete_enrollment!(enrollment_id) do
    Enrollment
    |> Repo.get!(enrollment_id)
    |> Repo.delete!()
  end

  @doc false
  def changeset(enrollments, attrs) do
    enrollments
    |> cast(attrs, [:name, :state])
    |> validate_required([:name, :state])
  end

  def state_options do
    [:closed, :opened, :finished]
  end
end
