defmodule CheckexTest do
  use ExUnit.Case, async: true
  doctest Checkex

  alias Checkex.{Text,Command}


  describe "when working with a simple checklist" do
    setup [:parse_simple_list]

    test "that we can fetch the title", %{rendered_list: rendered_list} do
      assert "ToDo" == rendered_list.title
    end

    test "that we can get at the steps", %{rendered_list: rendered_list} do
      assert 3 == Enum.count(rendered_list.steps)

      items = Enum.map(rendered_list.steps, &(&1.item))
      assert ["Step One", "Step Two", "Step Three"] == items

      expected_bodies = [
        [%Text{content: "Do some stuff!"}],
        [%Text{content: "Do some more stuff!"}],
        [%Text{content: "Do the last stuff!"}]
      ]
      actual_bodies = Enum.map(rendered_list.steps, &(&1.body))
      assert expected_bodies == actual_bodies
    end
  end

  describe "when working with a checklist containing shell commands" do
    setup [:parse_command_list]

    test "that we can fetch the title", %{rendered_list: rendered_list} do
      assert "Commands ToDo" == rendered_list.title
    end

    test "that we can get at the steps", %{rendered_list: rendered_list} do
      assert 2 == Enum.count(rendered_list.steps)

      items = Enum.map(rendered_list.steps, &(&1.item))
      assert ["Step One", "Step Two"] == items

      expected_bodies = [
        [%Text{content: "Do some stuff!"}],
        [%Command{content: "echo \"Hello World\""}],
      ]
      actual_bodies = Enum.map(rendered_list.steps, &(&1.body))
      assert expected_bodies == actual_bodies
    end
  end

  describe "when working with a checklist whose items have multiple body lines" do
    setup [:parse_complex_list]

    test "that we can fetch the title", %{rendered_list: rendered_list} do
      assert "Complex ToDo" == rendered_list.title
    end

    test "that we can get at the steps", %{rendered_list: rendered_list} do
      assert 4 == Enum.count(rendered_list.steps)

      items = Enum.map(rendered_list.steps, &(&1.item))
      assert ["Step One", "Step Two", "Step Three", "Step Four"] == items

      expected_bodies = [
        [%Text{content: "Do some stuff!"}],
        [
          %Text{content: "Make sure we're ready to rock!"},
          %Command{content: "echo \"Hello World\""}
        ],
        [
          %Text{content: "Here's the big one!"},
          %Checkex.Command{content: "./run_my_script"},
          %Checkex.Command{content: "echo \"Goodbye World!\""} 
        ],
        [%Text{content: "Finish it off"}],
      ]
      actual_bodies = Enum.map(rendered_list.steps, &(&1.body))
      assert expected_bodies == actual_bodies
    end
  end

  defp parse_simple_list(context) do
    simple_list = """
      # ToDo

      - Step One

        Do some stuff!

      - Step Two

        Do some more stuff!

      - Step Three

        Do the last stuff!

      """
    rendered_list = Checkex.parse(simple_list)
    Map.put(context, :rendered_list, rendered_list)
  end

  defp parse_command_list(context) do
    command_list = """
      # Commands ToDo

      - Step One

        Do some stuff!

      - Step Two

        `echo "Hello World"`

      """
    rendered_list = Checkex.parse(command_list)
    Map.put(context, :rendered_list, rendered_list)
  end

  defp parse_complex_list(context) do
    complex_list = """
      # Complex ToDo

      - Step One

        Do some stuff!

      - Step Two

        Make sure we're ready to rock!

        `echo "Hello World"`

      - Step Three

        Here's the big one!

        ```bash
        ./run_my_script
        echo "Goodbye World!"
        ```

      - Step Four

        Finish it off

      """
    rendered_list = Checkex.parse(complex_list)
    Map.put(context, :rendered_list, rendered_list)
  end
end
