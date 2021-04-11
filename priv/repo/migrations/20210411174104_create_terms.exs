defmodule PlanPicker.Repo.Migrations.CreateTerms do
  use Ecto.Migration

  def change do
    create_query = "CREATE TYPE week_type AS ENUM ('A', 'B')"
    drop_query = "DROP TYPE week_type"
    execute(create_query, drop_query)

    create table(:terms) do
      add :interval, :tstzrange
      add :location, :string
      add :week_type, :week_type
      add :class_id, references(:classes, on_delete: :delete_all)

      timestamps()
    end
    create constraint("terms", :in_two_week_range, check: "interval <@ '[1996-01-01 00:00, 1996-01-14 00:00]'")
    create constraint("terms", :no_overlap_in_group, exclude: "gist (class_id WITH =, interval WITH &&)")
    create index(:terms, [:class_id])
  end
end
