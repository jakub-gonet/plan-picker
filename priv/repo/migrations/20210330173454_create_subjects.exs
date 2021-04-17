defmodule PlanPicker.Repo.Migrations.CreateSubjects do
  use Ecto.Migration

  def change do
    create table(:subjects) do
      add :name, :string, null: false

      timestamps()
    end

  end
end
