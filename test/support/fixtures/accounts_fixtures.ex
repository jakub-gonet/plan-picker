defmodule PlanPicker.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PlanPicker.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_name, do: "Adam"
  def valid_user_last_name, do: "Nowak"
  def valid_user_index_no, do: "400400"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password(),
      name: valid_user_name(),
      last_name: valid_user_last_name(),
      index_no: valid_user_index_no()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> PlanPicker.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token, _] = String.split(captured.body, "[TOKEN]")
    token
  end
end
