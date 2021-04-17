defmodule PlanPicker.Repo.Migrations.CreateRoles do
  use Ecto.Migration

  def change do
    create_query = "CREATE TYPE user_role AS ENUM ('admin', 'moderator')"
    drop_query = "DROP TYPE user_role"
    execute(create_query, drop_query)

    create table(:roles) do
      add :name, :user_role, null: false
      add :user_id, references(:users)
      timestamps()
    end

  end
end
