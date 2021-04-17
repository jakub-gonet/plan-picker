defmodule PlanPicker.Repo.Migrations.CreateEnrollmentsUsers do
  use Ecto.Migration

  def change do
    create table(:enrollments_users) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :enrollment_id, references(:enrollments, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:enrollments_users, [:user_id, :enrollment_id], name: "enrollments_users_unique_fk")
  end
end
