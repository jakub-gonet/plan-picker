defmodule PlanPicker.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PlanPicker.Accounts` context.
  """

  def unique_password_auth_email, do: "password_auth#{System.unique_integer()}@example.com"
  def valid_password_auth_password, do: "hello world!"

  def valid_password_auth_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_password_auth_email(),
      password: valid_password_auth_password()
    })
  end

  def password_auth_fixture(attrs \\ %{}) do
    {:ok, password_auth} =
      attrs
      |> valid_password_auth_attributes()
      |> PlanPicker.Accounts.register_password_auth()

    password_auth
  end

  def extract_password_auth_token(fun) do
    {:ok, captured} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token, _] = String.split(captured.body, "[TOKEN]")
    token
  end
end
