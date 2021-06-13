defmodule PlanPicker.PointAssignmentLive do
  use PlanPickerWeb, :live_view
  alias PlanPicker.Term
  alias PlanPickerWeb.EnrollmentView

  def render(assigns) do
    render(EnrollmentView, "points_assignments.html", assigns)
  end

  def mount(_params, %{"term_id" => term_id}, socket) do
    term = Term.get_term!(term_id)

    {:ok, assign(socket, :term_id, term_id)}
  end
end
