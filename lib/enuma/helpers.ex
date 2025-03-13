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
end
