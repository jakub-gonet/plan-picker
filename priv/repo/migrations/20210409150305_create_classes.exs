defmodule PlanPicker.Repo.Migrations.CreateClasses do
  use Ecto.Migration

  def change do
    create table(:classes) do
      add :type, :string, null: false
      add :teacher_id, references(:teachers, on_delete: :delete_all)
      add :subject_id, references(:subjects, on_delete: :delete_all)

      timestamps()
    end

    create index(:classes, [:teacher_id])
    create index(:classes, [:subject_id])
  end
end
