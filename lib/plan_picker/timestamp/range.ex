defmodule Timestamp.Range do
  use Ecto.Type

  @year 1996
  @month 1
  @day 1

  @default_opts [lower_inclusive: true, upper_inclusive: false]
  @enforce_keys [:start, :end]
  defstruct [:start, :end, opts: []]

  @type t :: %__MODULE__{
          start: DateTime.t(),
          end: DateTime.t(),
          opts: [
            lower_inclusive: boolean(),
            upper_inclusive: boolean()
          ]
        }

  @spec new(DateTime.t(), DateTime.t(), Keyword.t()) :: t
  def new(range_start, range_end, opts \\ []) do
    opts = Keyword.merge(@default_opts, opts)

    %__MODULE__{
      start: range_start,
      end: range_end,
      opts: opts
    }
  end

  def from_time(start_time, end_time, weekday, opts \\ []) do
    offset = Timestamp.Day.get_offset(weekday)
    date = Date.new!(@year, @month, @day + offset)

    interval_start = DateTime.new!(date, start_time)
    interval_end = DateTime.new!(date, end_time)
    new(interval_start, interval_end, opts)
  end

  @impl Ecto.Type
  def type, do: :tstzrange

  @impl Ecto.Type
  def cast(term)
  def cast(%Timestamp.Range{} = range), do: {:ok, range}
  def cast(_), do: :error

  @impl Ecto.Type
  def load(term)

  def load(%Postgrex.Range{lower: %DateTime{}, upper: %DateTime{}} = range) do
    {:ok,
     Timestamp.Range.new(
       range.lower,
       range.upper,
       lower_inclusive: range.lower_inclusive,
       upper_inclusive: range.upper_inclusive
     )}
  end

  def load(_), do: :error

  @impl Ecto.Type
  def dump(%Timestamp.Range{} = range) do
    [lower_inclusive: lower_inclusive, upper_inclusive: upper_inclusive] = range.opts

    {:ok,
     %Postgrex.Range{
       lower: range.start,
       upper: range.end,
       lower_inclusive: lower_inclusive,
       upper_inclusive: upper_inclusive
     }}
  end

  def dump(_), do: :error
end

defimpl Inspect, for: Timestamp.Range do
  def inspect(
        %Timestamp.Range{
          start: range_start,
          end: range_end,
          opts: [lower_inclusive: lower_inc, upper_inclusive: upper_inc]
        },
        _
      ) do
    start_paren = if lower_inc, do: "[", else: "("
    end_paren = if upper_inc, do: "]", else: ")"
    "#Timestamp.Range<#{start_paren}#{inspect(range_start)}, #{inspect(range_end)}#{end_paren}>"
  end
end

defimpl Phoenix.HTML.Safe, for: Timestamp.Range do
  def to_iodata(
    %Timestamp.Range{
      start: range_start,
      end: range_end,
    }
  ) do
    "#{Phoenix.HTML.Safe.to_iodata(range_start)} - #{Phoenix.HTML.Safe.to_iodata(range_end)}"
  end
end
