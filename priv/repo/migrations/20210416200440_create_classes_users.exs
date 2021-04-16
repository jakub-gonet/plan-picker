defmodule PlanPicker.Repo.Migrations.CreateClassesUsers do
  use Ecto.Migration

  def change do
    create table(:classes_users) do
      add :class_id, references(:classes, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:classes_users, [:class_id, :user_id], name: :classes_users_unique_fk)
  end
end
