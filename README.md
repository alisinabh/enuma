# Enuma

[![Hex.pm](https://img.shields.io/hexpm/v/enuma.svg)](https://hex.pm/packages/enuma)
[![Hex Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/enuma)

Rust-like Enums for Elixir. Enuma makes it easy to define rich enumeration types similar to Rust, while maintaining Elixir's pattern matching capabilities.

## Features

- Define structured enum types with named variants
- No runtime performance overhead due to compile-time evaluation of macros
- Variants can contain no data or structured data
- Pattern matching on enum variants
- Guard-compatible matching with `is_*` macros
- Optional Ecto integration for database storage

## Installation

Add `enuma` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:enuma, "~> 0.1.0"}
  ]
end
```

## Usage

Enuma uses atoms for simple items and tuples for complex items (items with arguments). All Enuma
enuma helpers are macros so it will not have any runtime impact on performance.

### Basic Usage

```elixir
defmodule Shape do
  use Enuma

  defenum do
    item :circle, args: [float()]   # Circle with radius
    item :rectangle, args: [float(), float()]  # Rectangle with width and height
    item :triangle
  end
end

# Creating enum values
circle = Shape.circle(5.0)  # {:circle, 5.0}
rect = Shape.rectangle(4.0, 3.0)  # {:rectangle, 4.0, 3.0}
triangle = Shape.triangle()  # :triangle

# Require is needed to use the Enuma helpers since they are macros
require Shape

def calculate_area(shape) do
  case shape do
    Shape.circle(r) -> :math.pi() * r * r
    Shape.rectangle(w, h) -> w * h
    Shape.triangle() -> raise "Area calculation for triangle not implemented"
  end
end

# Guard expressions
def print_shape(shape) when Shape.is_circle(shape) do
  Shape.circle(radius) = shape
  IO.puts("Circle with radius #{radius}")
end
```

### Ecto Integration

Enuma provides Ecto integration for storing enum values in the database:

```elixir
defmodule DrawingObject do
  use Ecto.Schema

  schema "drawing_objects" do
    # Using map serialization to support all shape variants including those with parameters
    # Using string serialization only works with enums only holding simple types (no arguments)
    field :shape, Enuma.Ecto, type: Shape, ecto_type: :map

    timestamps()
  end
end
```

The `:map` serialization format supports all variant types, storing them in the database as JSON-compatible maps:

- Simple variants like `:triangle` are stored as `%{"key" => "triangle", "values" => []}`
- Complex variants like `{:circle, 5.0}` are stored as `%{"key" => "circle", "values" => [5.0]}`
- Multi-parameter variants like `{:rectangle, 4.0, 3.0}` are stored as `%{"key" => "rectangle", "values" => [4.0, 3.0]}`

Using with changesets:

```elixir
import Ecto.Changeset

# Valid values include all variants from your enum definition
params = %{
  shape: Shape.circle(5.0)
}

# Cast and validate enum values
changeset =
  %DrawingObject{}
  |> cast(params, [:shape])
  |> validate_required([:shape])
```

Read more about Ecto integration in the `Enuma.Ecto` module documentation.

## Documentation

Complete documentation is available at [https://hexdocs.pm/enuma](https://hexdocs.pm/enuma).

## License

MIT License. See LICENSE file for details.
