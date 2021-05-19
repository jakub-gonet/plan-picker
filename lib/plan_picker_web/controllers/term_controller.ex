defmodule PlanPickerWeb.TermController do
  use PlanPickerWeb, :controller

  def show(conn, %{"id" => id}) do
    term = PlanPicker.Term
    |> PlanPicker.Repo.get!(id)
    |> PlanPicker.Repo.preload(:class)

    render(conn, "show.html", term: term)
  end

  def new(conn, %{"class_id" => class_id}) do
    changeset = %PlanPicker.Term{}
    |> Ecto.Changeset.change()

    render(conn, "new.html", changeset: changeset, class_id: class_id)
  end

  def create(conn, %{"class_id" => class_id, "term" => term_attrs}) do
    class = PlanPicker.Class
    |> PlanPicker.Repo.get!(class_id)

    PlanPicker.Term.add_term(term_attrs, class)

    redirect(conn, to: Routes.class_path(conn, :show, class_id))
  end
end
