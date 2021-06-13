defmodule PlanPickerWeb.EnrollmentLive do
  use PlanPickerWeb, :live_view
  alias PlanPicker.{Accounts, Class, Enrollment, Term}
  alias PlanPickerWeb.EnrollmentView

  # TODO: move that
  @max_points 8
  @min_points 0
  @max_points_per_subject 20

  def max_points, do: @max_points

  def render(assigns) do
    Phoenix.View.render(EnrollmentView, "show.html", assigns)
  end

  def mount(%{"id" => enrollment_id}, %{"user_token" => token}, socket) do
    user = Accounts.get_user_by_session_token(token)

    terms =
      enrollment_id
      |> Enrollment.get_enrollment!()
      |> Enrollment.get_terms_for_enrollment()
      |> Enum.map(&fetch_points_assignments(&1, user))

    socket =
      socket
      |> assign(:terms, terms)
      |> assign(:user, user)

    {:ok, socket}
  end

  def handle_event("add_points", %{"id" => term_id}, socket) do
    user = socket.assigns[:user]

    new_points = update_points(term_id, user, :increment)

    group_number = socket.assigns[:terms][term_id].group_number

    new_terms =
      Enum.map(socket.assigns[:terms], fn v ->
        if v.group_number == group_number do
          Map.put(v, :assigned_points, new_points)
        else
          v
        end
      end)

    {:noreply, assign(socket, :terms, new_terms)}
  end

  def handle_event("remove_points", %{"id" => term_id}, socket) do
    user = socket.assigns[:user]

    new_points = update_points(term_id, user, :decrement)

    group_number = socket.assigns[:terms][term_id].group_number

    new_terms =
      Enum.map(socket.assigns[:terms], fn v ->
        if v.group_number == group_number do
          Map.put(v, :assigned_points, new_points)
        else
          v
        end
      end)

    {:noreply, assign(socket, :terms, new_terms)}
  end

  defp update_points(term_id, user, what) do
    class = Term.get_term!(term_id, preload: [:class]).class

    points = Class.get_points(class, user)

    points =
      clamp_assigned_points(
        points,
        case what do
          :increment -> points + 1
          :decrement -> points - 1
        end
      )

    Class.assign_points!(class, user, points)

    points
  end

  defp clamp_assigned_points(_, new_points)
       when @min_points <= new_points and new_points <= @max_points,
       do: new_points

  defp clamp_assigned_points(current_points, _), do: current_points

  defp fetch_points_assignments(%{id: term_id} = term, user) do
    class = Term.get_term!(term_id, preload: [:class]).class
    Map.put(term, :assigned_points, Class.get_points(class, user))
  end
end
