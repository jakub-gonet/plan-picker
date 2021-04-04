defmodule PlanPicker.Role do
  use Ecto.Schema
  import Ecto.Changeset

  schema "roles" do
    field :name, Ecto.Enum, values: [:moderator, :admin]
    belongs_to :user, PlanPicker.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(roles, attrs) do
    roles
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
