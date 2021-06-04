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
alias PlanPicker.{Repo, Role, Accounts, DataLoader, Enrollment}

admin =
  Repo.insert!(%PlanPicker.Accounts.User{
    email: "admin@test.com",
    hashed_password: Bcrypt.hash_pwd_salt("admin"),
    name: "admin",
    last_name: "admin",
    index_no: "000000"
  })

Role.assign_role(admin, :moderator)
Role.assign_role(admin, :admin)

moderator =
  Repo.insert!(%Accounts.User{
    email: "moderator@test.com",
    hashed_password: Bcrypt.hash_pwd_salt("moderator"),
    name: "moderator",
    last_name: "moderator",
    index_no: "000001"
  })

Role.assign_role(moderator, :moderator)

user =
  Repo.insert!(%Accounts.User{
    email: "user@test.com",
    hashed_password: Bcrypt.hash_pwd_salt("user"),
    name: "user",
    last_name: "user",
    index_no: "000002"
  })

"priv/repo/seeds/example_plan_data.csv"
|> DataLoader.import()
|> DataLoader.load_imported_data_to_db()

enrollment = Enrollment.get_enrollment_by_name("3 semestr")
Enrollment.assign_user_to_enrollment(enrollment, user)
