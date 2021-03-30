defmodule PlanPicker.AccountsTest do
  use PlanPicker.DataCase

  alias PlanPicker.Accounts
  import PlanPicker.AccountsFixtures
  alias PlanPicker.Accounts.{PasswordAuth, PasswordAuthToken}

  describe "get_password_auth_by_email/1" do
    test "does not return the password_auth if the email does not exist" do
      refute Accounts.get_password_auth_by_email("unknown@example.com")
    end

    test "returns the password_auth if the email exists" do
      %{id: id} = password_auth = password_auth_fixture()
      assert %PasswordAuth{id: ^id} = Accounts.get_password_auth_by_email(password_auth.email)
    end
  end

  describe "get_password_auth_by_email_and_password/2" do
    test "does not return the password_auth if the email does not exist" do
      refute Accounts.get_password_auth_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the password_auth if the password is not valid" do
      password_auth = password_auth_fixture()
      refute Accounts.get_password_auth_by_email_and_password(password_auth.email, "invalid")
    end

    test "returns the password_auth if the email and password are valid" do
      %{id: id} = password_auth = password_auth_fixture()

      assert %PasswordAuth{id: ^id} =
               Accounts.get_password_auth_by_email_and_password(password_auth.email, valid_password_auth_password())
    end
  end

  describe "get_password_auth!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_password_auth!(-1)
      end
    end

    test "returns the password_auth with the given id" do
      %{id: id} = password_auth = password_auth_fixture()
      assert %PasswordAuth{id: ^id} = Accounts.get_password_auth!(password_auth.id)
    end
  end

  describe "register_password_auth/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Accounts.register_password_auth(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Accounts.register_password_auth(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_password_auth(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 80 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = password_auth_fixture()
      {:error, changeset} = Accounts.register_password_auth(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register_password_auth(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers password_auth with a hashed password" do
      email = unique_password_auth_email()
      {:ok, password_auth} = Accounts.register_password_auth(valid_password_auth_attributes(email: email))
      assert password_auth.email == email
      assert is_binary(password_auth.hashed_password)
      assert is_nil(password_auth.confirmed_at)
      assert is_nil(password_auth.password)
    end
  end

  describe "change_password_auth_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_password_auth_registration(%PasswordAuth{})
      assert changeset.required == [:password, :email]
    end

    test "allows fields to be set" do
      email = unique_password_auth_email()
      password = valid_password_auth_password()

      changeset =
        Accounts.change_password_auth_registration(
          %PasswordAuth{},
          valid_password_auth_attributes(email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_password_auth_email/2" do
    test "returns a password_auth changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_password_auth_email(%PasswordAuth{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_password_auth_email/3" do
    setup do
      %{password_auth: password_auth_fixture()}
    end

    test "requires email to change", %{password_auth: password_auth} do
      {:error, changeset} = Accounts.apply_password_auth_email(password_auth, valid_password_auth_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{password_auth: password_auth} do
      {:error, changeset} =
        Accounts.apply_password_auth_email(password_auth, valid_password_auth_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{password_auth: password_auth} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.apply_password_auth_email(password_auth, valid_password_auth_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{password_auth: password_auth} do
      %{email: email} = password_auth_fixture()

      {:error, changeset} =
        Accounts.apply_password_auth_email(password_auth, valid_password_auth_password(), %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{password_auth: password_auth} do
      {:error, changeset} =
        Accounts.apply_password_auth_email(password_auth, "invalid", %{email: unique_password_auth_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{password_auth: password_auth} do
      email = unique_password_auth_email()
      {:ok, password_auth} = Accounts.apply_password_auth_email(password_auth, valid_password_auth_password(), %{email: email})
      assert password_auth.email == email
      assert Accounts.get_password_auth!(password_auth.id).email != email
    end
  end

  describe "deliver_update_email_instructions/3" do
    setup do
      %{password_auth: password_auth_fixture()}
    end

    test "sends token through notification", %{password_auth: password_auth} do
      token =
        extract_password_auth_token(fn url ->
          Accounts.deliver_update_email_instructions(password_auth, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert password_auth_token = Repo.get_by(PasswordAuthToken, token: :crypto.hash(:sha256, token))
      assert password_auth_token.password_auth_id == password_auth.id
      assert password_auth_token.sent_to == password_auth.email
      assert password_auth_token.context == "change:current@example.com"
    end
  end

  describe "update_password_auth_email/2" do
    setup do
      password_auth = password_auth_fixture()
      email = unique_password_auth_email()

      token =
        extract_password_auth_token(fn url ->
          Accounts.deliver_update_email_instructions(%{password_auth | email: email}, password_auth.email, url)
        end)

      %{password_auth: password_auth, token: token, email: email}
    end

    test "updates the email with a valid token", %{password_auth: password_auth, token: token, email: email} do
      assert Accounts.update_password_auth_email(password_auth, token) == :ok
      changed_password_auth = Repo.get!(PasswordAuth, password_auth.id)
      assert changed_password_auth.email != password_auth.email
      assert changed_password_auth.email == email
      assert changed_password_auth.confirmed_at
      assert changed_password_auth.confirmed_at != password_auth.confirmed_at
      refute Repo.get_by(PasswordAuthToken, password_auth_id: password_auth.id)
    end

    test "does not update email with invalid token", %{password_auth: password_auth} do
      assert Accounts.update_password_auth_email(password_auth, "oops") == :error
      assert Repo.get!(PasswordAuth, password_auth.id).email == password_auth.email
      assert Repo.get_by(PasswordAuthToken, password_auth_id: password_auth.id)
    end

    test "does not update email if password_auth email changed", %{password_auth: password_auth, token: token} do
      assert Accounts.update_password_auth_email(%{password_auth | email: "current@example.com"}, token) == :error
      assert Repo.get!(PasswordAuth, password_auth.id).email == password_auth.email
      assert Repo.get_by(PasswordAuthToken, password_auth_id: password_auth.id)
    end

    test "does not update email if token expired", %{password_auth: password_auth, token: token} do
      {1, nil} = Repo.update_all(PasswordAuthToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.update_password_auth_email(password_auth, token) == :error
      assert Repo.get!(PasswordAuth, password_auth.id).email == password_auth.email
      assert Repo.get_by(PasswordAuthToken, password_auth_id: password_auth.id)
    end
  end

  describe "change_password_auth_password/2" do
    test "returns a password_auth changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_password_auth_password(%PasswordAuth{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_password_auth_password(%PasswordAuth{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_password_auth_password/3" do
    setup do
      %{password_auth: password_auth_fixture()}
    end

    test "validates password", %{password_auth: password_auth} do
      {:error, changeset} =
        Accounts.update_password_auth_password(password_auth, valid_password_auth_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{password_auth: password_auth} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_password_auth_password(password_auth, valid_password_auth_password(), %{password: too_long})

      assert "should be at most 80 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{password_auth: password_auth} do
      {:error, changeset} =
        Accounts.update_password_auth_password(password_auth, "invalid", %{password: valid_password_auth_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{password_auth: password_auth} do
      {:ok, password_auth} =
        Accounts.update_password_auth_password(password_auth, valid_password_auth_password(), %{
          password: "new valid password"
        })

      assert is_nil(password_auth.password)
      assert Accounts.get_password_auth_by_email_and_password(password_auth.email, "new valid password")
    end

    test "deletes all tokens for the given password_auth", %{password_auth: password_auth} do
      _ = Accounts.generate_password_auth_session_token(password_auth)

      {:ok, _} =
        Accounts.update_password_auth_password(password_auth, valid_password_auth_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(PasswordAuthToken, password_auth_id: password_auth.id)
    end
  end

  describe "generate_password_auth_session_token/1" do
    setup do
      %{password_auth: password_auth_fixture()}
    end

    test "generates a token", %{password_auth: password_auth} do
      token = Accounts.generate_password_auth_session_token(password_auth)
      assert password_auth_token = Repo.get_by(PasswordAuthToken, token: token)
      assert password_auth_token.context == "session"

      # Creating the same token for another password_auth should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%PasswordAuthToken{
          token: password_auth_token.token,
          password_auth_id: password_auth_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_password_auth_by_session_token/1" do
    setup do
      password_auth = password_auth_fixture()
      token = Accounts.generate_password_auth_session_token(password_auth)
      %{password_auth: password_auth, token: token}
    end

    test "returns password_auth by token", %{password_auth: password_auth, token: token} do
      assert session_password_auth = Accounts.get_password_auth_by_session_token(token)
      assert session_password_auth.id == password_auth.id
    end

    test "does not return password_auth for invalid token" do
      refute Accounts.get_password_auth_by_session_token("oops")
    end

    test "does not return password_auth for expired token", %{token: token} do
      {1, nil} = Repo.update_all(PasswordAuthToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_password_auth_by_session_token(token)
    end
  end

  describe "delete_session_token/1" do
    test "deletes the token" do
      password_auth = password_auth_fixture()
      token = Accounts.generate_password_auth_session_token(password_auth)
      assert Accounts.delete_session_token(token) == :ok
      refute Accounts.get_password_auth_by_session_token(token)
    end
  end

  describe "deliver_password_auth_confirmation_instructions/2" do
    setup do
      %{password_auth: password_auth_fixture()}
    end

    test "sends token through notification", %{password_auth: password_auth} do
      token =
        extract_password_auth_token(fn url ->
          Accounts.deliver_password_auth_confirmation_instructions(password_auth, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert password_auth_token = Repo.get_by(PasswordAuthToken, token: :crypto.hash(:sha256, token))
      assert password_auth_token.password_auth_id == password_auth.id
      assert password_auth_token.sent_to == password_auth.email
      assert password_auth_token.context == "confirm"
    end
  end

  describe "confirm_password_auth/1" do
    setup do
      password_auth = password_auth_fixture()

      token =
        extract_password_auth_token(fn url ->
          Accounts.deliver_password_auth_confirmation_instructions(password_auth, url)
        end)

      %{password_auth: password_auth, token: token}
    end

    test "confirms the email with a valid token", %{password_auth: password_auth, token: token} do
      assert {:ok, confirmed_password_auth} = Accounts.confirm_password_auth(token)
      assert confirmed_password_auth.confirmed_at
      assert confirmed_password_auth.confirmed_at != password_auth.confirmed_at
      assert Repo.get!(PasswordAuth, password_auth.id).confirmed_at
      refute Repo.get_by(PasswordAuthToken, password_auth_id: password_auth.id)
    end

    test "does not confirm with invalid token", %{password_auth: password_auth} do
      assert Accounts.confirm_password_auth("oops") == :error
      refute Repo.get!(PasswordAuth, password_auth.id).confirmed_at
      assert Repo.get_by(PasswordAuthToken, password_auth_id: password_auth.id)
    end

    test "does not confirm email if token expired", %{password_auth: password_auth, token: token} do
      {1, nil} = Repo.update_all(PasswordAuthToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.confirm_password_auth(token) == :error
      refute Repo.get!(PasswordAuth, password_auth.id).confirmed_at
      assert Repo.get_by(PasswordAuthToken, password_auth_id: password_auth.id)
    end
  end

  describe "deliver_password_auth_reset_password_instructions/2" do
    setup do
      %{password_auth: password_auth_fixture()}
    end

    test "sends token through notification", %{password_auth: password_auth} do
      token =
        extract_password_auth_token(fn url ->
          Accounts.deliver_password_auth_reset_password_instructions(password_auth, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert password_auth_token = Repo.get_by(PasswordAuthToken, token: :crypto.hash(:sha256, token))
      assert password_auth_token.password_auth_id == password_auth.id
      assert password_auth_token.sent_to == password_auth.email
      assert password_auth_token.context == "reset_password"
    end
  end

  describe "get_password_auth_by_reset_password_token/1" do
    setup do
      password_auth = password_auth_fixture()

      token =
        extract_password_auth_token(fn url ->
          Accounts.deliver_password_auth_reset_password_instructions(password_auth, url)
        end)

      %{password_auth: password_auth, token: token}
    end

    test "returns the password_auth with valid token", %{password_auth: %{id: id}, token: token} do
      assert %PasswordAuth{id: ^id} = Accounts.get_password_auth_by_reset_password_token(token)
      assert Repo.get_by(PasswordAuthToken, password_auth_id: id)
    end

    test "does not return the password_auth with invalid token", %{password_auth: password_auth} do
      refute Accounts.get_password_auth_by_reset_password_token("oops")
      assert Repo.get_by(PasswordAuthToken, password_auth_id: password_auth.id)
    end

    test "does not return the password_auth if token expired", %{password_auth: password_auth, token: token} do
      {1, nil} = Repo.update_all(PasswordAuthToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_password_auth_by_reset_password_token(token)
      assert Repo.get_by(PasswordAuthToken, password_auth_id: password_auth.id)
    end
  end

  describe "reset_password_auth_password/2" do
    setup do
      %{password_auth: password_auth_fixture()}
    end

    test "validates password", %{password_auth: password_auth} do
      {:error, changeset} =
        Accounts.reset_password_auth_password(password_auth, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{password_auth: password_auth} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.reset_password_auth_password(password_auth, %{password: too_long})
      assert "should be at most 80 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{password_auth: password_auth} do
      {:ok, updated_password_auth} = Accounts.reset_password_auth_password(password_auth, %{password: "new valid password"})
      assert is_nil(updated_password_auth.password)
      assert Accounts.get_password_auth_by_email_and_password(password_auth.email, "new valid password")
    end

    test "deletes all tokens for the given password_auth", %{password_auth: password_auth} do
      _ = Accounts.generate_password_auth_session_token(password_auth)
      {:ok, _} = Accounts.reset_password_auth_password(password_auth, %{password: "new valid password"})
      refute Repo.get_by(PasswordAuthToken, password_auth_id: password_auth.id)
    end
  end

  describe "inspect/2" do
    test "does not include password" do
      refute inspect(%PasswordAuth{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
