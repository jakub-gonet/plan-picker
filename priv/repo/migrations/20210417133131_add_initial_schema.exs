defmodule PlanPicker.Repo.Migrations.AddInitialSchema do
  use Ecto.Migration

  def change do
    add_user_tables()
    add_enrollments()
    add_subject_tables()
    add_class_tables()
  end

  defp add_user_tables do
    add_users()
    add_auth_tokens()
    add_roles()
  end

  defp add_subject_tables do
    add_subjects()
    add_teachers()
  end

  defp add_class_tables do
    add_classes()
    add_terms()
    add_points_assignments()
  end

  defp add_users do
    create table(:users) do
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime

      add :name, :string, null: false, size: 50
      add :last_name, :string, null: false, size: 100
      add :index_no, :string, null: false, size: 10

      timestamps()
    end

    create unique_index(:users, [:email])
  end

  defp add_auth_tokens do
    create table(:users_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])
  end

  defp add_roles do
    create_query = "CREATE TYPE user_role AS ENUM ('admin', 'moderator')"
    drop_query = "DROP TYPE user_role"
    execute(create_query, drop_query)

    create table(:roles) do
      add :name, :user_role, null: false
      add :user_id, references(:users)
      timestamps()
    end
  end

  defp add_subjects do
    create table(:subjects) do
      add :name, :string, null: false
      add :enrollment_id, references(:enrollments, on_delete: :delete_all)

      timestamps()
    end
  end

  defp add_teachers do
    create table(:teachers) do
      add :name, :string, null: false
      add :surname, :string, null: false

      timestamps()
    end
  end

  defp add_classes do
    create table(:classes) do
      add :type, :string, null: false
      add :teacher_id, references(:teachers, on_delete: :delete_all)
      add :subject_id, references(:subjects, on_delete: :delete_all)

      timestamps()
    end
    create index(:classes, [:teacher_id])
    create index(:classes, [:subject_id])

    create table(:classes_users) do
      add :class_id, references(:classes, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end
    create unique_index(:classes_users, [:class_id, :user_id], name: :classes_users_unique_fk)
  end

  defp add_terms do
    create_query = "CREATE TYPE week_type AS ENUM ('A', 'B')"
    drop_query = "DROP TYPE week_type"
    execute(create_query, drop_query)

    create table(:terms) do
      add :interval, :tstzrange, null: false
      add :location, :string
      add :week_type, :week_type
      add :class_id, references(:classes, on_delete: :delete_all)

      timestamps()
    end
    create constraint("terms", :in_two_week_range, check: "interval <@ '[1996-01-01 00:00, 1996-01-14 00:00]'")
    create constraint("terms", :no_overlap_in_group, exclude: "gist (class_id WITH =, interval WITH &&)")
    create index(:terms, [:class_id])
  end

  defp add_points_assignments do
    create table(:points_assignments) do
      add :points, :integer, null: false
      add :user_id, references(:users, on_delete: :delete_all)
      add :term_id, references(:terms, on_delete: :delete_all)

      timestamps()
    end
    create unique_index(:points_assignments, [:user_id, :term_id], name: "points_assignments_unique_index")
  end

  defp add_enrollments do
    create table(:enrollments) do
      add :name, :string
      add :state, :string

      timestamps()
    end

    create table(:enrollments_users) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :enrollment_id, references(:enrollments, on_delete: :delete_all)

      timestamps()
    end
    create unique_index(:enrollments_users, [:user_id, :enrollment_id], name: "enrollments_users_unique_fk")
  end
end
