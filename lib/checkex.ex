defmodule Checkex do
  defstruct title: "", steps: []

  defmodule Step, do: defstruct item: "", body: []
  defmodule Text, do: defstruct content: ""
  defmodule Command, do: defstruct content: ""
  defmodule CommandBlock, do: defstruct language: "", commands: []

  def parse(source) when is_binary(source) do
    source
    |> String.split("\n", trim: true)
    |> Enum.map(&String.trim/1)
    |> parse_lines
  end

  defp parse_lines(["#" <> title | body]) do
    steps = parse_body(body)
    struct(__MODULE__, title: String.trim(title), steps: steps)
  end

  defp parse_body([]), do: []

  defp parse_body(body) do
    parse_body([], body)
  end

  defp parse_body(list, ["-" <> line | rest]) do
    step = struct(Step, item: String.trim(line))
    parse_children(list, step, rest)
  end

  defp parse_children(list, step, body = ["-" <> _line | _rest]) do
    step = struct(step, body: Enum.reverse(step.body))
    parse_body([step | list], body)
  end

  defp parse_children(list, step, [line | rest]) do
    {step, rest} = update_step(step, parse_line(line), rest)
    parse_children(list, step, rest)
  end

  defp parse_children(list, step, []) do
    [step | list] |> Enum.reverse
  end

  defp update_step(step, block=%CommandBlock{}, body = ["-" <> _line | _rest]) do
    step = struct(step, body: block.commands ++ step.body)
    {step, body}
  end

  defp update_step(step, block=%CommandBlock{commands: cs}, [line | rest]) do
    case parse_line(line) do
      %CommandBlock{} ->
        update_step(step, block, rest)
      %Text{content: line} ->
        command = struct(Command, content: line)
        update_step(step, struct(block, commands: [command | cs]), rest)
    end
  end

  defp update_step(step, line, rest) do
    step = struct(step, body: [line | step.body])
    {step, rest}
  end

  defp parse_line("```" <> language) do
    struct(CommandBlock, language: language)
  end

  defp parse_line("`" <> line) do
    command = String.trim_trailing(line, "`")
    struct(Command, content: command)
  end

  defp parse_line(line) do
    struct(Text, content: line)
  end

  defimpl Enumerable do
    def count(list), do: Enumerable.List.count(list.steps)
    def member?(list, element), do: Enumerable.List.member?(list.steps, element)
    def reduce(list, acc, fun), do: Enumerable.List.reduce(list.steps, acc, fun)
  end
end
