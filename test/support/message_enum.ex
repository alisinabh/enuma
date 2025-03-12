defmodule MessageEnum do
  use Enuma

  defenum [
    :quit,
    move: %{x: integer(), y: integer()},
    write: String.t(),
    change_color: [integer(), integer(), integer()]
  ]
end
