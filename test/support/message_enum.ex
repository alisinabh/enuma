defmodule MessageEnum do
  use Enuma

  defenum do
    item :quit
    item :move, args: %{x: integer(), y: integer()}
    item :write, args: String.t()
    item :change_color, args: [integer(), integer(), integer()]
  end
end
