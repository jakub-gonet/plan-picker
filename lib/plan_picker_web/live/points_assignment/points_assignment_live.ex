defmodule PlanPicker.PointAssignmentLive do
  use PlanPickerWeb, :live_view
  alias PlanPicker.{Accounts, Class, Term}
  alias PlanPickerWeb.EnrollmentView

  # TODO: move that
  @max_points 20
  @min_points 0

  def max_points, do: @max_points

  def render(assigns) do
    render(EnrollmentView, "points_assignments.html", assigns)
  end

  def mount(_params, %{"term_id" => term_id, "user_token" => token}, socket) do
    term = Term.get_term!(term_id)
    current_user = Accounts.get_user_by_session_token(token)

    socket =
      socket
      |> assign(:user_id, current_user.id)
      |> assign(:term_id, term_id)
      |> assign(:assigned_points, Class.get_points(term.class, current_user) || 0)

    {:ok, socket}
  end

  def handle_event("add_points", _value, socket) do
    %{term_id: term_id, user_id: user_id, assigned_points: points} = Map.get(socket, :assigns)
    new_points = update_points(term_id, user_id, points, points + 1)
    {:noreply, assign(socket, :assigned_points, new_points)}
  end

  def handle_event("remove_points", _value, socket) do
    %{term_id: term_id, user_id: user_id, assigned_points: points} = Map.get(socket, :assigns)
    new_points = update_points(term_id, user_id, points, points - 1)
    {:noreply, assign(socket, :assigned_points, new_points)}
  end

  defp update_points(term_id, user_id, old_points, new_points) do
    new_points = clamp_assigned_points(old_points, new_points)

    class = Term.get_term!(term_id, preload: [:class]).class
    user = Accounts.get_user!(user_id)

    Class.assign_points!(class, user, new_points)
    new_points
  end

  defp clamp_assigned_points(_, new_points)
       when @min_points <= new_points and new_points <= @max_points,
       do: new_points

  defp clamp_assigned_points(current_points, _), do: current_points
end
