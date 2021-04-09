defmodule PlanPicker.Repo.Migrations.CreateTeachers do
  use Ecto.Migration

  def change do
    create table(:teachers) do
      add :name, :string
      add :surname, :string

      timestamps()
    end

  end
end
