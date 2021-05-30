defmodule PlanPicker.Repo.Migrations.AddGroupsNToClasses do
  use Ecto.Migration

  def change do
    alter table(:classes) do
      add :group_number, :integer
    end
    create constraint("classes", :nullable_lecture, check: "group_number IS NOT NULL OR type = 'W'")
  end
end
