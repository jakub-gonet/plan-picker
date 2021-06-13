defmodule PlanPicker.PointAssigmentLive do
  use PlanPickerWeb, :live_view
  alias PlanPickerWeb.EnrollmentView

  def render(assigns) do
    render(EnrollmentView, "points_assignments.html", assigns)
  end

  def mount(_params, %{"term_id" => term_id}, socket) do
    {:ok, assign(socket, :term_id, term_id)}
  end
end
