defmodule PlanPicker.Accounts.PasswordAuthNotifier do
  # For simplicity, this module simply logs messages to the terminal.
  # You should replace it by a proper email or notification tool, such as:
  #
  #   * Swoosh - https://hexdocs.pm/swoosh
  #   * Bamboo - https://hexdocs.pm/bamboo
  #
  defp deliver(to, body) do
    require Logger
    Logger.debug(body)
    {:ok, %{to: to, body: body}}
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(password_auth, url) do
    deliver(password_auth.email, """

    ==============================

    Hi #{password_auth.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a password_auth password.
  """
  def deliver_reset_password_instructions(password_auth, url) do
    deliver(password_auth.email, """

    ==============================

    Hi #{password_auth.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a password_auth email.
  """
  def deliver_update_email_instructions(password_auth, url) do
    deliver(password_auth.email, """

    ==============================

    Hi #{password_auth.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end
