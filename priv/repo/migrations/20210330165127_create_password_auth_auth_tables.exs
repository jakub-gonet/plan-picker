defmodule PlanPicker.Repo.Migrations.CreatePasswordAuthAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:password_auth) do
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      timestamps()
    end

    create unique_index(:password_auth, [:email])

    create table(:password_auth_tokens) do
      add :password_auth_id, references(:password_auth, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:password_auth_tokens, [:password_auth_id])
    create unique_index(:password_auth_tokens, [:context, :token])
  end
end
