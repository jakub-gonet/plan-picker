defmodule PlanPicker.Class do
  use Ecto.Schema
  import Ecto.Changeset

  schema "classes" do
    field :type, :string
    belongs_to :teacher, PlanPicker.Teacher
    belongs_to :subject, PlanPicker.Subject

    many_to_many(:users, PlanPicker.Accounts.User, join_through: "classes_users")

    timestamps()
  end

  @doc false
  def changeset(class, attrs) do
    class
    |> cast(attrs, [:type])
    |> validate_required([:type])
  end
end
