defmodule EnumaTest do
  use ExUnit.Case
  doctest Enuma

  require MessageEnum

  test "enum values are correct" do
    assert MessageEnum.quit() = :quit
    assert MessageEnum.move(%{x: 1, y: 2}) = {:move, %{x: 1, y: 2}}
    assert MessageEnum.write("HI") = {:write, "HI"}
    assert MessageEnum.change_color(1, 2, 3) = {:change_color, 1, 2, 3}
  end

  test "is_value? works as expected" do
    assert MessageEnum.is_quit(MessageEnum.quit())
    assert MessageEnum.is_move(MessageEnum.move(%{x: 1, y: 2}))
    assert MessageEnum.is_write(MessageEnum.write("HI"))
    assert MessageEnum.is_change_color(MessageEnum.change_color(1, 2, 3))
  end

  test "enuma cannot redefine already defined enum" do
    assert_raise RuntimeError, ~r/Enuma: Cannot redefine already defined enum/, fn ->
      defmodule MultiDefEnum do
        use Enuma

        defenum do
          item :a
          item :b
        end

        defenum do
          item :a
          item :c
        end
      end
    end
  end
end
