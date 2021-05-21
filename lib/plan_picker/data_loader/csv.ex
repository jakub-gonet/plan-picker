defmodule PlanPicker.DataLoader.Csv do
  alias NimbleCSV.RFC4180, as: CSV

  def import(path) do
    path
    |> File.stream!()
    |> CSV.parse_stream()
    |> Enum.map(&parse_csv/1)
  end

  defp parse_csv([
         semester,
         subject,
         type,
         group,
         teacher,
         location,
         week_type,
         day,
         start_time,
         end_time
       ]) do
    type = parse_type(type)
    start_time = parse_time(start_time)

    %{
      semester: String.to_integer(semester),
      subject: :binary.copy(subject),
      type: type,
      group_number: parse_group(group, type),
      teacher: parse_teacher(teacher),
      location: :binary.copy(location),
      week_type: parse_week_type(week_type),
      day: parse_weekday(day),
      start_time: start_time,
      end_time: parse_end_time(end_time, start_time)
    }
  end

  defp parse_group("", :lecture), do: nil
  defp parse_group(group, _) when group != "", do: String.to_integer(group)

  defp parse_teacher(teacher) do
    [last_name, first_name] =
      teacher
      |> :binary.copy()
      |> String.split(" ", trim: true, parts: 2)

    %{surname: last_name, name: first_name}
  end

  defp parse_time(time) do
    [hour, minutes] = String.split(time, ":")
    {:ok, parsed} = Time.new(String.to_integer(hour), String.to_integer(minutes), 0)
    parsed
  end

  defp parse_end_time("", start_time), do: Time.add(start_time, 90 * 60)

  defp parse_end_time(end_time_s, _) do
    [hour, minutes] = String.split(end_time_s, ":")
    {:ok, parsed} = Time.new(String.to_integer(hour), String.to_integer(minutes), 0)
    parsed
  end

  defp parse_week_type(""), do: :both_weeks
  defp parse_week_type("A"), do: :week_a
  defp parse_week_type("B"), do: :week_b

  defp parse_weekday(str) do
    str
    |> String.downcase()
    |> parse_weekday_lower()
  end

  defp parse_weekday_lower("pn"), do: :monday
  defp parse_weekday_lower("wt"), do: :tuesday
  defp parse_weekday_lower("sr"), do: :wednesday
  defp parse_weekday_lower("cz"), do: :thursday
  defp parse_weekday_lower("pt"), do: :friday

  defp parse_type("W"), do: :lecture
  defp parse_type("C"), do: :class
  defp parse_type("L"), do: :laboratory
end
