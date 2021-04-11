defmodule PlanPicker.Repo.Migrations.SetupDbExtensions do
  use Ecto.Migration

  def change do
    create_query = "CREATE EXTENSION citext"
    drop_query = "DROP EXTENSION citext"
    execute(create_query, drop_query)

    create_query = "CREATE EXTENSION btree_gist"
    drop_query = "DROP EXTENSION btree_gist"
    execute(create_query, drop_query)
  end
end
