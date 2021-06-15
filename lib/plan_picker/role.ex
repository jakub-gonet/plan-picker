defmodule PlanPicker.Role do
  use PlanPicker.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  alias PlanPicker.{Accounts, Repo, Role}

  schema "roles" do
    field :name, Ecto.Enum, values: [:moderator, :admin]
    belongs_to :user, PlanPicker.Accounts.User

    timestamps()
  end

  def get_roles_for(user) do
    user
    |> Ecto.assoc(:role)
    |> Repo.all()
    |> Enum.map(& &1.name)
  end

  @doc """
  Checks whether the user has a role with name: role_name.
  """
  def has_role?(user, role_name) do
    query =
      from u in Accounts.User,
        join: r in assoc(u, :role),
        where: r.name == ^role_name and u.id == ^user.id

    Repo.exists?(query)
  end

  @doc """
  Adds a role with name: role_name to user if user does not have it already.

  Does nothing if user has role role_name.
  """
  def assign_role(user, role_name) do
    if not has_role?(user, role_name) do
      %Role{name: role_name}
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:user, user)
      |> Repo.insert!()
    end
  end

  @doc """
  Removes role with name: role_name from user if user has it already.

  Does nothing if user doesn't have role role_name.
  """
  def unassign_role(user, role_name) do
    query =
      from u in Accounts.User,
        join: r in assoc(u, :role),
        where: r.name == ^role_name and u.id == ^user.id

    Repo.delete_all(query)
  end

  @doc false
  def changeset(roles, attrs) do
    roles
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
