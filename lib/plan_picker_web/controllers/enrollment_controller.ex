defmodule PlanPickerWeb.EnrollmentController do
  use PlanPickerWeb, :controller

  alias PlanPicker.Enrollment

  def index(conn, _params) do
    enrollments = Enrollment.get_enrollments_for_user(conn.assigns[:current_user])

    render(conn, "index.html", enrollments: enrollments)
  end

  def show(conn, %{"id" => enrollment_id}) do
    enrollment = Enrollment.get_enrollment!(enrollment_id)

    render(conn, "show.html", enrollment: enrollment)
  end
end
