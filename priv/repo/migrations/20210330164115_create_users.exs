defmodule PlanPicker.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string, null: false, size: 50
      add :last_name, :string, null: false, size: 100
      add :index_no, :string, null: false, size: 10

      timestamps()
    end

  end
end
