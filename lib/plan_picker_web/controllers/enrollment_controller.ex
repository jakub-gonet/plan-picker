defmodule PlanPickerWeb.EnrollmentController do
  use PlanPickerWeb, :controller

  def get_enrollments_for_current_user(conn, _params) do
    enrollments = PlanPicker.Enrollment.get_enrollments_for_user(conn.assigns[:current_user])

    render(conn, "index.html", enrollments: enrollments)
  end

  def index(conn, _params) do
    enrollments = PlanPicker.Repo.all(PlanPicker.Enrollment)

    render(conn, "index.html", enrollments: enrollments)
  end

  def new(conn, _params) do
    changeset = Ecto.Changeset.change(%PlanPicker.Enrollment{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"enrollment" => enrollment_params}) do
    enrollment = PlanPicker.Enrollment.create_enrollment(enrollment_params)

    redirect(conn, to: Routes.enrollment_path(conn, :show, enrollment.id))
  end

  def show(conn, %{"id" => enrollment_id}) do
    enrollment =
      PlanPicker.Enrollment
      |> PlanPicker.Repo.get!(enrollment_id)
      |> PlanPicker.Repo.preload(:users)
      |> PlanPicker.Repo.preload(:subjects)

    render(conn, "show.html", enrollment: enrollment)
  end

  def delete(conn, %{"id" => enrollment_id}) do
    PlanPicker.Enrollment.delete_enrollment(enrollment_id)

    conn
    |> put_flash(:info, "Enrollment deleted.")
    |> redirect(to: Routes.enrollment_path(conn, :index))
  end

  def edit(conn, %{"id" => enrollment_id}) do
    changeset =
      PlanPicker.Enrollment
      |> PlanPicker.Repo.get!(enrollment_id)
      |> PlanPicker.Repo.preload(:users)
      |> PlanPicker.Repo.preload(:subjects)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.cast(%{}, [:id])

    render(conn, "edit.html",
      changeset: changeset,
      state_options: PlanPicker.Enrollment.state_options(),
      enrollment_id: enrollment_id
    )
  end

  def update(conn, %{"enrollment" => enrollment_params, "id" => enrollment_id}) do
    PlanPicker.Enrollment.update_enrollment(enrollment_id, enrollment_params)

    conn
    |> put_flash(:info, "Enrollment updated")
    |> redirect(to: Routes.enrollment_path(conn, :show, enrollment_id))
  end
end
