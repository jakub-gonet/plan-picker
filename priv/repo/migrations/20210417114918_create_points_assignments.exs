defmodule PlanPicker.Repo.Migrations.CreatePointsAssignments do
  use Ecto.Migration

  def change do
    create table(:points_assignments) do
      add :points, :integer, null: false
      add :user_id, references(:users, on_delete: :delete_all)
      add :term_id, references(:terms, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:points_assignments, [:user_id, :term_id], name: "points_assignments_unique_index")
  end
end
