defmodule Enuma.Helpers do
  @moduledoc false

  def type_match?(value, {:|, _meta, _args} = ast) do
    types = unor_ast(ast)
    Enum.any?(types, &type_match?(value, &1))
  end

  def type_match?(value, {:integer, _meta, _args}) do
    is_integer(value)
  end

  def type_match?(value, {:non_neg_integer, _meta, _args}) do
    is_integer(value) and value >= 0
  end

  def type_match?(value, {:pos_integer, _meta, _args}) do
    is_integer(value) and value > 0
  end

  def type_match?(value, {:float, _meta, _args}) do
    is_float(value)
  end

  def type_match?(value, {:boolean, _meta, _args}) do
    is_boolean(value)
  end

  def type_match?(_value, {:any, _meta, _args}) do
    true
  end

  def type_match?(
        value,
        {{:., _meta,
          [
            {:__aliases__, _, [:String]},
            :t
          ]}, _, []}
      ) do
    is_binary(value) and String.valid?(value)
  end

  def type_match?(value, {:%{}, _, args}) do
    if is_map(value) do
      Enum.reduce_while(args, true, fn {key, type}, acc ->
        if type_match?(value[key], type) do
          {:cont, acc}
        else
          {:halt, false}
        end
      end)
    else
      false
    end
  end

  def type_match?(_value, type) do
    raise "Type matching for #{inspect(type)} is not implemented"
  end

  def unor_ast(ast, acc \\ [])

  def unor_ast({:|, _meta, [left, right]}, acc) do
    unor_ast(right, [left | acc])
  end

  def unor_ast(last, acc) do
    Enum.reverse([last | acc])
  end

  def to_map(value) when is_tuple(value) do
    [item_key | values] = Tuple.to_list(value)
    {:ok, %{"key" => Atom.to_string(item_key), "values" => values}}
  end

  def to_map(value) when is_atom(value) do
    {:ok, %{"key" => Atom.to_string(value), "values" => []}}
  end

  def from_map(%{"key" => key, "values" => values}, type_module) do
    with {:ok, key} <- type_module.enuma_to_atom(key) do
      item = type_module.__items_map__()[key]
      item_args_len = Enum.count(Keyword.fetch!(item, :args))

      cond do
        item_args_len != Enum.count(values) -> {:error, :invalid_enum_arity}
        item_args_len == 0 -> {:ok, key}
        true -> {:ok, List.to_tuple([key | values])}
      end
    end
  end

  def from_map(_invalid, _type_module) do
    {:error, :invalid_dumped_value}
  end

  def from_string(key, type_module) do
    type_module.enuma_to_atom(key)
  end

  def to_string(key) when is_atom(key) do
    {:ok, Atom.to_string(key)}
  end

  def to_string(value) when is_tuple(value) do
    {:error, :unsupported_enuma_ecto_type}
  end
end
