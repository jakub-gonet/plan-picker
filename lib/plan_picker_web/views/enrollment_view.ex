defmodule PlanPickerWeb.EnrollmentView do
  use PlanPickerWeb, :view

  def terms_for_day(terms, day) do
    terms
    |> Enum.filter(&Timestamp.Day.is_on_day(&1.interval, day))
    |> Enum.sort_by(& &1.interval.start)
  end
end
