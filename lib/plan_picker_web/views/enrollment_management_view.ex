defmodule PlanPickerWeb.EnrollmentManagementView do
  use PlanPickerWeb, :view

  def selected?(selected, el), do: el in selected
end
