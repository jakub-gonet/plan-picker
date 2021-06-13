defmodule PlanPickerWeb.EnrollmentController do
  use PlanPickerWeb, :controller

  alias PlanPicker.Enrollment
  alias PlanPickerWeb.UserAuth

  def index(conn, _params) do
    enrollments = conn |> UserAuth.current_user() |> Enrollment.get_enrollments_for_user()

    render(conn, "index.html", enrollments: enrollments)
  end

  def show(conn, %{"id" => enrollment_id}) do
    terms =
      enrollment_id
      |> Enrollment.get_enrollment!()
      |> Enrollment.get_terms_for_enrollment()

    render(conn, "show.html", terms: terms)
  end
end
