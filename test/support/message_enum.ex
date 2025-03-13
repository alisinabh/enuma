defmodule MessageEnum do
  use Enuma

  defenum do
    item :quit
    item :move, args: %{x: integer(), y: integer()}
    item :write, args: String.t()
    item :change_color, args: [integer(), integer(), integer()]
  end
end

defmodule MessageEnumSchema do
  use Ecto.Schema

  embedded_schema do
    field(:type, Enuma.Ecto, type: MessageEnum, ecto_type: :string)
  end
end
