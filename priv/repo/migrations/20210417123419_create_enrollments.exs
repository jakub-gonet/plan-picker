defmodule PlanPicker.Repo.Migrations.CreateEnrollments do
  use Ecto.Migration

  def change do
    create table(:enrollments) do
      add :name, :string
      add :state, :string

      timestamps()
    end
  end
end
