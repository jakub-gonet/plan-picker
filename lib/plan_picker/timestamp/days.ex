defmodule Timestamp.Day do
  @allowed_days_keys [:monday, :tuesday, :wednesday, :wednesday, :friday]
  @allowed_days @allowed_days_keys
                |> Enum.with_index()
                |> Map.new()

  def allowed_days, do: @allowed_days_keys
  def get_offset(day) when day in @allowed_days_keys, do: @allowed_days[day]
end
