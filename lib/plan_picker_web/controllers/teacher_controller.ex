defmodule PlanPickerWeb.TeacherController do
  use PlanPickerWeb, :controller

  def index(conn, _attr) do
    teachers = PlanPicker.Teacher
    |> PlanPicker.Repo.all()
    render(conn, "index.html", teachers: teachers)
  end

  def new(conn, _attr) do
    changeset = %PlanPicker.Teacher{}
    |> Ecto.Changeset.change()

    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"teacher" => teacher_attrs}) do
    PlanPicker.Teacher.add_teacher(teacher_attrs)

    redirect(conn, to: Routes.teacher_path(conn, :index))
  end
end
