defmodule Timestamp.Day do
  @allowed_days_keys [:monday, :tuesday, :wednesday, :thursday, :friday]
  @allowed_days @allowed_days_keys
                |> Enum.with_index()
                |> Map.new()

  def allowed_days, do: @allowed_days_keys
  def get_offset(day) when day in @allowed_days_keys, do: @allowed_days[day] + 1

  def is_on_day(timestamp, day) when day in @allowed_days_keys do
    timestamp.start.day === get_offset(day) && timestamp.end.day === get_offset(day)
  end
end
