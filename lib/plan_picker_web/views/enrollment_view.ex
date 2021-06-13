defmodule PlanPickerWeb.EnrollmentView do
  use PlanPickerWeb, :view

  def terms_for_day(terms, day) do
    terms
    |> Enum.filter(&Timestamp.Day.is_on_day(&1.interval, day))
    |> Enum.sort_by(& &1.interval.start)
  end

  def get_width_perc(0), do: 0

  def get_width_perc(points) when points > 0,
    do: trunc(100 * points / PlanPicker.PointAssignmentLive.max_points())

  def display_week_type(%{week_type: nil}), do: nil
  def display_week_type(%{week_type: type}), do: "Week #{type}"

  def prefix_if_not_empty(str, _) when is_nil(str) or str == "", do: nil
  def prefix_if_not_empty(str, prefix), do: "#{prefix}#{str}"
end
