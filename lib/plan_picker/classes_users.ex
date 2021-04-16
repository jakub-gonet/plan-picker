defmodule PlanPicker.ClassesUsers do
  use Ecto.Schema
  import Ecto.Changeset

  schema "classes_users" do
    field :group, :id
    field :user, :id

    timestamps()
  end

  @doc false
  def changeset(classes_users, attrs) do
    classes_users
    |> cast(attrs, [])
    |> validate_required([])
  end
end
