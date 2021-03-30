defmodule PlanPicker.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias PlanPicker.Repo
  alias PlanPicker.Accounts.{PasswordAuth, PasswordAuthToken, PasswordAuthNotifier}

  ## Database getters

  @doc """
  Gets a password_auth by email.

  ## Examples

      iex> get_password_auth_by_email("foo@example.com")
      %PasswordAuth{}

      iex> get_password_auth_by_email("unknown@example.com")
      nil

  """
  def get_password_auth_by_email(email) when is_binary(email) do
    Repo.get_by(PasswordAuth, email: email)
  end

  @doc """
  Gets a password_auth by email and password.

  ## Examples

      iex> get_password_auth_by_email_and_password("foo@example.com", "correct_password")
      %PasswordAuth{}

      iex> get_password_auth_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_password_auth_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    password_auth = Repo.get_by(PasswordAuth, email: email)
    if PasswordAuth.valid_password?(password_auth, password), do: password_auth
  end

  @doc """
  Gets a single password_auth.

  Raises `Ecto.NoResultsError` if the PasswordAuth does not exist.

  ## Examples

      iex> get_password_auth!(123)
      %PasswordAuth{}

      iex> get_password_auth!(456)
      ** (Ecto.NoResultsError)

  """
  def get_password_auth!(id), do: Repo.get!(PasswordAuth, id)

  ## Password auth registration

  @doc """
  Registers a password_auth.

  ## Examples

      iex> register_password_auth(%{field: value})
      {:ok, %PasswordAuth{}}

      iex> register_password_auth(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_password_auth(attrs) do
    %PasswordAuth{}
    |> PasswordAuth.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking password_auth changes.

  ## Examples

      iex> change_password_auth_registration(password_auth)
      %Ecto.Changeset{data: %PasswordAuth{}}

  """
  def change_password_auth_registration(%PasswordAuth{} = password_auth, attrs \\ %{}) do
    PasswordAuth.registration_changeset(password_auth, attrs, hash_password: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the password_auth email.

  ## Examples

      iex> change_password_auth_email(password_auth)
      %Ecto.Changeset{data: %PasswordAuth{}}

  """
  def change_password_auth_email(password_auth, attrs \\ %{}) do
    PasswordAuth.email_changeset(password_auth, attrs)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_password_auth_email(password_auth, "valid password", %{email: ...})
      {:ok, %PasswordAuth{}}

      iex> apply_password_auth_email(password_auth, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_password_auth_email(password_auth, password, attrs) do
    password_auth
    |> PasswordAuth.email_changeset(attrs)
    |> PasswordAuth.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the password_auth email using the given token.

  If the token matches, the password_auth email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_password_auth_email(password_auth, token) do
    context = "change:#{password_auth.email}"

    with {:ok, query} <- PasswordAuthToken.verify_change_email_token_query(token, context),
         %PasswordAuthToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(password_auth_email_multi(password_auth, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp password_auth_email_multi(password_auth, email, context) do
    changeset = password_auth |> PasswordAuth.email_changeset(%{email: email}) |> PasswordAuth.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:password_auth, changeset)
    |> Ecto.Multi.delete_all(:tokens, PasswordAuthToken.password_auth_and_contexts_query(password_auth, [context]))
  end

  @doc """
  Delivers the update email instructions to the given password_auth.

  ## Examples

      iex> deliver_update_email_instructions(password_auth, current_email, &Routes.password_auth_update_email_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_update_email_instructions(%PasswordAuth{} = password_auth, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, password_auth_token} = PasswordAuthToken.build_email_token(password_auth, "change:#{current_email}")

    Repo.insert!(password_auth_token)
    PasswordAuthNotifier.deliver_update_email_instructions(password_auth, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the password_auth password.

  ## Examples

      iex> change_password_auth_password(password_auth)
      %Ecto.Changeset{data: %PasswordAuth{}}

  """
  def change_password_auth_password(password_auth, attrs \\ %{}) do
    PasswordAuth.password_changeset(password_auth, attrs, hash_password: false)
  end

  @doc """
  Updates the password_auth password.

  ## Examples

      iex> update_password_auth_password(password_auth, "valid password", %{password: ...})
      {:ok, %PasswordAuth{}}

      iex> update_password_auth_password(password_auth, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_password_auth_password(password_auth, password, attrs) do
    changeset =
      password_auth
      |> PasswordAuth.password_changeset(attrs)
      |> PasswordAuth.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:password_auth, changeset)
    |> Ecto.Multi.delete_all(:tokens, PasswordAuthToken.password_auth_and_contexts_query(password_auth, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{password_auth: password_auth}} -> {:ok, password_auth}
      {:error, :password_auth, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_password_auth_session_token(password_auth) do
    {token, password_auth_token} = PasswordAuthToken.build_session_token(password_auth)
    Repo.insert!(password_auth_token)
    token
  end

  @doc """
  Gets the password_auth with the given signed token.
  """
  def get_password_auth_by_session_token(token) do
    {:ok, query} = PasswordAuthToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_session_token(token) do
    Repo.delete_all(PasswordAuthToken.token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc """
  Delivers the confirmation email instructions to the given password_auth.

  ## Examples

      iex> deliver_password_auth_confirmation_instructions(password_auth, &Routes.password_auth_confirmation_url(conn, :confirm, &1))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_password_auth_confirmation_instructions(confirmed_password_auth, &Routes.password_auth_confirmation_url(conn, :confirm, &1))
      {:error, :already_confirmed}

  """
  def deliver_password_auth_confirmation_instructions(%PasswordAuth{} = password_auth, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if password_auth.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, password_auth_token} = PasswordAuthToken.build_email_token(password_auth, "confirm")
      Repo.insert!(password_auth_token)
      PasswordAuthNotifier.deliver_confirmation_instructions(password_auth, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a password_auth by the given token.

  If the token matches, the password_auth account is marked as confirmed
  and the token is deleted.
  """
  def confirm_password_auth(token) do
    with {:ok, query} <- PasswordAuthToken.verify_email_token_query(token, "confirm"),
         %PasswordAuth{} = password_auth <- Repo.one(query),
         {:ok, %{password_auth: password_auth}} <- Repo.transaction(confirm_password_auth_multi(password_auth)) do
      {:ok, password_auth}
    else
      _ -> :error
    end
  end

  defp confirm_password_auth_multi(password_auth) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:password_auth, PasswordAuth.confirm_changeset(password_auth))
    |> Ecto.Multi.delete_all(:tokens, PasswordAuthToken.password_auth_and_contexts_query(password_auth, ["confirm"]))
  end

  ## Reset password

  @doc """
  Delivers the reset password email to the given password_auth.

  ## Examples

      iex> deliver_password_auth_reset_password_instructions(password_auth, &Routes.password_auth_reset_password_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_password_auth_reset_password_instructions(%PasswordAuth{} = password_auth, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, password_auth_token} = PasswordAuthToken.build_email_token(password_auth, "reset_password")
    Repo.insert!(password_auth_token)
    PasswordAuthNotifier.deliver_reset_password_instructions(password_auth, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the password_auth by reset password token.

  ## Examples

      iex> get_password_auth_by_reset_password_token("validtoken")
      %PasswordAuth{}

      iex> get_password_auth_by_reset_password_token("invalidtoken")
      nil

  """
  def get_password_auth_by_reset_password_token(token) do
    with {:ok, query} <- PasswordAuthToken.verify_email_token_query(token, "reset_password"),
         %PasswordAuth{} = password_auth <- Repo.one(query) do
      password_auth
    else
      _ -> nil
    end
  end

  @doc """
  Resets the password_auth password.

  ## Examples

      iex> reset_password_auth_password(password_auth, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %PasswordAuth{}}

      iex> reset_password_auth_password(password_auth, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_password_auth_password(password_auth, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:password_auth, PasswordAuth.password_changeset(password_auth, attrs))
    |> Ecto.Multi.delete_all(:tokens, PasswordAuthToken.password_auth_and_contexts_query(password_auth, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{password_auth: password_auth}} -> {:ok, password_auth}
      {:error, :password_auth, changeset, _} -> {:error, changeset}
    end
  end
end
