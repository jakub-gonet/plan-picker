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

import Ecto.Query, only: [from: 2]

PlanPicker.Repo.delete_all(from role in PlanPicker.Role, select: role)

admin = case PlanPicker.Repo.get_by(PlanPicker.Accounts.User, email: "admin@test.com") do
  nil ->
    %PlanPicker.Accounts.User{email: "admin@test.com", hashed_password: Bcrypt.hash_pwd_salt("admin"), name: "admin", last_name: "admin", index_no: "000000"}
    |> PlanPicker.Repo.insert!()
  r -> r
end

PlanPicker.Role.assign_role(admin, :moderator)
PlanPicker.Role.assign_role(admin, :admin)

moderator = case PlanPicker.Repo.get_by(PlanPicker.Accounts.User, email: "moderator@test.com") do
  nil ->
    %PlanPicker.Accounts.User{email: "moderator@test.com", hashed_password: Bcrypt.hash_pwd_salt("moderator"), name: "moderator", last_name: "moderator", index_no: "000001"}
    |> PlanPicker.Repo.insert!()
  r -> r
end

PlanPicker.Role.assign_role(moderator, :moderator)
