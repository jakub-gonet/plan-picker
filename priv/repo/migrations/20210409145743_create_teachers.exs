defmodule PlanPicker.Repo.Migrations.CreateTeachers do
  use Ecto.Migration

  def change do
    create table(:teachers) do
      add :name, :string, null: false
      add :surname, :string, null: false

      timestamps()
    end

  end
end
