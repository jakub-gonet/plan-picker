defmodule PlanPicker.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :index_no, :string
    field :last_name, :string
    field :name, :string

    has_one :password_auth, PlanPicker.Accounts.PasswordAuth
    has_many :role, PlanPicker.Role
    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :last_name, :index_no])
    |> validate_required([:name, :last_name, :index_no])
  end
end
