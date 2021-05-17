defmodule PlanPickerWeb.SubjectController do
  use PlanPickerWeb, :controller

  def new(conn, %{"enrollment_id" => enrollment_id}) do
    changeset = %PlanPicker.Subject{}
    |> Ecto.Changeset.change()

    render(conn, "new.html", enrollment_id: enrollment_id, changeset: changeset)
  end

  def create(conn, %{"enrollment_id" => enrollment_id, "subject" => subject_attrs}) do
    enrollment = PlanPicker.Enrollment
    |> PlanPicker.Repo.get!(enrollment_id);

    PlanPicker.Subject.create_subject(subject_attrs, enrollment)
    conn
    |> put_flash(:info, "Subject created.")
    |> redirect(to: Routes.enrollment_path(conn, :show, enrollment_id))
  end

  def show(conn, %{"subject_id" => subject_id}) do
    subject = PlanPicker.Subject
    |> PlanPicker.Repo.get!(subject_id)
    |> PlanPicker.Repo.preload(:classes)

    render(conn, "show.html", subject: subject)
  end
end
