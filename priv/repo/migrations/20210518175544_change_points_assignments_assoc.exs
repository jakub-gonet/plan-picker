defmodule PlanPicker.Repo.Migrations.ChangePointsAssignmentsAssoc do
  use Ecto.Migration

  def change do
    alter table(:points_assignments) do
      remove :term_id
      add :class_id, references(:classes, on_delete: :delete_all)
    end
  end
end
