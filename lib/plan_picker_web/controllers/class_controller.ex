defmodule PlanPickerWeb.ClassController do
  use PlanPickerWeb, :controller

  def show(conn, %{"id" => class_id}) do
    class =
      PlanPicker.Class
      |> PlanPicker.Repo.get!(class_id)
      |> PlanPicker.Repo.preload([:subject, :terms, :teacher, :users, :points_assignments])

    render(conn, "show.html", class: class)
  end

  def new(conn, %{"subject_id" => subject_id}) do
    changeset = Ecto.Changeset.change(%PlanPicker.Class{})

    teachers = PlanPicker.Repo.all(PlanPicker.Teacher)

    render(conn, "new.html", changeset: changeset, teachers: teachers, subject_id: subject_id)
  end

  def create(conn, %{"class" => class_attrs, "subject_id" => subject_id}) do
    subject = PlanPicker.Repo.get!(PlanPicker.Subject, subject_id)

    class = PlanPicker.Class.add_class(class_attrs, subject)

    redirect(conn, to: Routes.class_path(conn, :assign_teacher, class.id))
  end

  def assign_teacher(conn, %{"class_id" => class_id}) do
    teachers = PlanPicker.Repo.all(PlanPicker.Teacher)

    render(conn, "assign_teacher.html", class_id: class_id, teachers: teachers)
  end

  def put_teacher(conn, %{"class_id" => class_id, "teacher_id" => teacher_id}) do
    class = PlanPicker.Repo.get!(PlanPicker.Class, class_id)
    teacher = PlanPicker.Repo.get!(PlanPicker.Teacher, teacher_id)
    PlanPicker.Class.assign_teacher(class, teacher)

    redirect(conn, to: Routes.class_path(conn, :show, class.id))
  end
end
