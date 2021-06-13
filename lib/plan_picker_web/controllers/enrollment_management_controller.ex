defmodule PlanPickerWeb.EnrollmentManagementController do
  use PlanPickerWeb, :controller

  alias PlanPicker.Enrollment
  alias PlanPickerWeb.UserAuth

  def index(conn, _params) do
    if Enum.member?(conn.assigns[:roles], :admin) do
      render(conn, "index.html", enrollments: Enrollment.get_all_enrollments())
    else
      enrollments = conn |> UserAuth.current_user() |> Enrollment.get_enrollments_for_user()
      render(conn, "index.html",
        enrollments: enrollments
      )
    end
  end

  def show(conn, %{"id" => enrollment_id}) do
    enrollment = Enrollment.get_enrollment!(enrollment_id)

    render(conn, "show.html", enrollment: enrollment)
  end

  def new(conn, _params) do
    changeset = Ecto.Changeset.change(%Enrollment{})

    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"enrollment" => enrollment_params}) do
    enrollment = Enrollment.create_enrollment(enrollment_params)

    conn
    |> put_flash(:info, "Enrollment created.")
    |> redirect(to: Routes.enrollment_management_path(conn, :show, enrollment.id))
  end

  def delete(conn, %{"id" => enrollment_id}) do
    Enrollment.delete_enrollment!(enrollment_id)

    conn
    |> put_flash(:info, "Enrollment deleted.")
    |> redirect(to: Routes.enrollment_management_path(conn, :index))
  end
end
