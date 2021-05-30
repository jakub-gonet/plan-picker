defmodule PlanPicker.Utils do
  def group_by(data, keys) do
    Enum.reduce(data, %{}, fn x, acc ->
      keys =
        keys
        |> Enum.map(&x[&1])
        |> access_keys()

      update_in(acc, keys, fn list -> [x | list] end)
    end)
  end

  defp access_keys([key]), do: [Access.key(key, [])]
  defp access_keys([key | rest]), do: [Access.key(key, %{}) | access_keys(rest)]
end
