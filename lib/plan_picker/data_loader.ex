defmodule PlanPicker.DataLoader do
  defdelegate import(path), to: PlanPicker.DataLoader.Csv
  alias PlanPicker.{Class, Enrollment, Utils, Subject, Term, Teacher, Repo}

  def load_imported_data_to_db(data) do
    Repo.transaction(fn ->
      for {semester_n, rows} <- Utils.group_by(data, [:semester]) do
        enrollment = Enrollment.create_enrollment(%{name: "#{semester_n} semestr"})

        subjects =
          create_and_map_from(
            data,
            :subject,
            &Subject.create_subject!(%{name: &1}, enrollment)
          )

        teachers = create_and_map_from(data, :teacher, &Teacher.create_teacher!/1)

        rows
        |> Utils.group_by([:subject, :group_number])
        |> Enum.each(fn {subject_name, groups} ->
          Enum.each(groups, fn {_group_n, terms} ->
            %{teacher: teacher_name} = unify_terms(terms)
            add_group(terms, subjects[subject_name], teachers[teacher_name])
          end)
        end)
      end
    end)
  end

  defp create_and_map_from(data, key, kv_f) do
    data
    |> Enum.map(& &1[key])
    |> Enum.uniq()
    |> Enum.map(&{&1, kv_f.(&1)})
    |> Map.new()
  end

  defp add_group(terms, subject, teacher) do
    %{type: type, group_number: group_n} = unify_terms(terms)

    class =
      Class.create_class!(
        %{type: transform_class_type(type), group_number: group_n},
        subject,
        teacher
      )

    Enum.each(terms, &add_term(&1, class))
  end

  defp add_term(
         %{
           start_time: start_t,
           end_time: end_t,
           location: loc,
           day: weekday,
           week_type: week_type
         },
         class
       ) do
    Term.create_term!(
      %{
        interval: %{start: start_t, end: end_t, weekday: weekday},
        location: loc,
        week_type: transform_week_type(week_type)
      },
      class
    )
  end

  defp unify_terms(terms) do
    [term] =
      Enum.uniq_by(terms, fn
        %{group_number: group, semester: sem, subject: subj, teacher: teacher} ->
          {group, sem, subj, teacher}
      end)

    term
  end

  defp transform_week_type(:week_a), do: "A"
  defp transform_week_type(:week_b), do: "B"
  defp transform_week_type(:both_weeks), do: nil

  defp transform_class_type(:lecture), do: "W"
  defp transform_class_type(:class), do: "C"
  defp transform_class_type(:laboratory), do: "L"
end
