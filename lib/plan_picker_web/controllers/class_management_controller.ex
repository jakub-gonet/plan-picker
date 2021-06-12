defmodule PlanPickerWeb.ClassManagementController do
  use PlanPickerWeb, :controller

  def index(conn, %{
        "enrollment_id" => enrollment_id,
        "subject_id" => subject_id,
        "class_id" => class_id
      }) do
    enrollment = PlanPicker.Enrollment.get_enrollment!(enrollment_id)

    selected_subject = PlanPicker.Subject.get_subject!(subject_id)

    selected_class = PlanPicker.Class.get_class!(class_id)

    render(conn, "index.html",
      enrollment: enrollment,
      selected_subject: selected_subject,
      selected_class: selected_class
    )
  end

  def index(conn, %{"enrollment_id" => enrollment_id, "subject_id" => subject_id}) do
    enrollment = PlanPicker.Enrollment.get_enrollment!(enrollment_id)

    selected = PlanPicker.Subject.get_subject!(subject_id)

    render(conn, "index.html",
      enrollment: enrollment,
      selected_subject: selected,
      selected_class: nil
    )
  end

  def index(conn, %{"id" => enrollment_id}) do
    enrollment = PlanPicker.Enrollment.get_enrollment!(enrollment_id)

    case enrollment.subjects do
      [selected | _] ->
        redirect(conn,
          to: Routes.class_management_path(conn, :index, enrollment.id, selected.id)
        )

      _ ->
        render(conn, "index.html",
          enrollment: enrollment,
          selected_subject: nil,
          selected_class: nil
        )
    end
  end
end
