if Code.ensure_loaded?(Ecto.Type) do
  defmodule Enuma.Ecto do
    @moduledoc """
    Ecto type for Enuma Enums.

    ## Using Enuma.Ecto with Ecto schemas

    The `Enuma.Ecto` type allows you to use Enuma enums in your Ecto schemas.
    It supports two storage formats: `:string` and `:map`.

    ### Basic Usage

    To use an Enuma enum in your Ecto schema:

    ```elixir
    defmodule MySchema do
      use Ecto.Schema

      schema "my_table" do
        field :status, Enuma.Ecto, type: StatusEnum, ecto_type: :string
      end
    end
    ```

    ### Storage Formats

    #### String Format (`:string`)

    When using `:string` as the `ecto_type`, the enum will be stored as a string in the database.
    This format only supports simple enum values (atoms without arguments).

    ```elixir
    field :status, Enuma.Ecto, type: StatusEnum, ecto_type: :string
    ```

    With this configuration:
    - `:pending` will be stored as `"pending"` in the database
    - Complex enum values (tuples with arguments) are not supported and will result in an error

    #### Map Format (`:map`)

    When using `:map` as the `ecto_type`, the enum will be stored as a JSON map in the database.
    This format supports both simple enum values and complex enum values with arguments.

    ```elixir
    field :message, Enuma.Ecto, type: MessageEnum, ecto_type: :map
    ```

    With this configuration items will be stored as maps with a `"key"` and `"values"` item.

    ### Ecto Changesets

    When working with changesets, you can use the enum values directly:

    ```elixir
    def changeset(schema, params) do
      schema
      |> cast(params, [:status])
      |> validate_required([:status])
    end
    ```

    You can then pass enum values in your params:

    ```elixir
    MySchema.changeset(%MySchema{}, %{status: })
    # Or with complex values
    MySchema.changeset(%MySchema{}, %{message: {:move, %{x: 1, y: 2}}})
    ```
    """

    use Ecto.ParameterizedType

    alias Enuma.Helpers

    def type(%{ecto_type: ecto_type}), do: ecto_type

    def init(opts),
      do: %{type: Keyword.fetch!(opts, :type), ecto_type: Keyword.get(opts, :ecto_type, :string)}

    def cast(data, params) do
      if params.type.valid?(data) do
        {:ok, data}
      else
        :error
      end
    end

    def load(data, _loader, %{ecto_type: :map} = params) do
      Helpers.from_map(data, params.type)
    end

    def load(data, _loader, %{ecto_type: :string} = params) do
      Helpers.from_string(data, params.type)
    end

    def dump(data, _dumper, %{ecto_type: :map}) do
      Helpers.to_map(data)
    end

    def dump(data, _dumper, %{ecto_type: :string}) do
      Helpers.to_string(data)
    end

    def equal?(a, b, _params) do
      a == b
    end

    def embed_as(_format, _params) do
      :dump
    end
  end
end
