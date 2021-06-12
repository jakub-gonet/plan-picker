defmodule PlanPickerWeb.EnrollmentManagementController do
  use PlanPickerWeb, :controller

  alias PlanPicker.Enrollment

  def index(conn, _params) do
    enrollments = Enrollment.get_all_enrollments()

    render(conn, "index.html", enrollments: enrollments)
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

  def edit(conn, %{"id" => enrollment_id}) do
    changeset =
      Enrollment.get_enrollment!(enrollment_id)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.cast(%{}, [:id])

    render(conn, "edit.html",
      changeset: changeset,
      state_options: Enrollment.state_options(),
      enrollment_id: enrollment_id
    )
  end

  def update(conn, %{"enrollment" => enrollment_params, "id" => enrollment_id}) do
    Enrollment.update_enrollment(enrollment_id, enrollment_params)

    conn
    |> put_flash(:info, "Enrollment updated")
    |> redirect(to: Routes.enrollment_management_path(conn, :show, enrollment_id))
  end

  def delete(conn, %{"id" => enrollment_id}) do
    Enrollment.delete_enrollment(enrollment_id)

    conn
    |> put_flash(:info, "Enrollment deleted.")
    |> redirect(to: Routes.enrollment_management_path(conn, :index))
  end
end
