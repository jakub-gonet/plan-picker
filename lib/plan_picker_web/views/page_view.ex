defmodule PlanPickerWeb.PageView do
  use PlanPickerWeb, :view

  alias PlanPicker.Enrollment

  def render_assigned_enrollments(conn, current_user) do
    enrollments = Enrollment.get_enrollments_for_user(current_user)

    render(PlanPickerWeb.EnrollmentView, "index.html", conn: conn, enrollments: enrollments)
  end
end
