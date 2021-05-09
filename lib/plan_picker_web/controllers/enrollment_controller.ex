defmodule PlanPickerWeb.EnrollmentController do
  use PlanPickerWeb, :controller

  def get_enrollments_for_current_user(conn, _params) do
    enrollments = conn.assigns[:current_user]
    |> PlanPicker.Enrollment.get_enrollments_for_user()

    render(conn, "index.html", enrollments: enrollments)
  end
end
