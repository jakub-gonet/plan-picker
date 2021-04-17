defmodule PlanPicker.Repo.Migrations.AddSubjectEnrollmentAssoc do
  use Ecto.Migration

  def change do
    alter table(:subjects) do
      add :enrollment_id, references(:enrollments, on_delete: :nothing)
    end
  end
end
