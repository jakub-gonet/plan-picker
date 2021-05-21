defmodule PlanPickerWeb.TeacherController do
  use PlanPickerWeb, :controller

  def index(conn, _attr) do
    teachers = PlanPicker.Repo.all(PlanPicker.Teacher)

    render(conn, "index.html", teachers: teachers)
  end

  def new(conn, _attr) do
    changeset = Ecto.Changeset.change(%PlanPicker.Teacher{})

    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"teacher" => teacher_attrs}) do
    PlanPicker.Teacher.add_teacher(teacher_attrs)

    redirect(conn, to: Routes.teacher_path(conn, :index))
  end
end
