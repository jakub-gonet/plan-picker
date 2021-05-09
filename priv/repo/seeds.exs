# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     PlanPicker.Repo.insert!(%PlanPicker.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

admin = %PlanPicker.Accounts.User{email: "admin@test.com", hashed_password: Bcrypt.hash_pwd_salt("admin"), name: "admin", last_name: "admin", index_no: "000000"}
|> PlanPicker.Repo.insert!(on_conflict: :nothing)
PlanPicker.Role.assign_role(admin, :moderator)
PlanPicker.Role.assign_role(admin, :admin)
