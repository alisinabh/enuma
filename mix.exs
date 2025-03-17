defmodule Enuma.MixProject do
  use Mix.Project

  def project do
    [
      app: :enuma,
      deps: deps(),
      docs: &docs/0,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      homepage_url: "https://github.com/alisinabh/enuma",
      name: "Enuma",
      package: package(),
      source_url: "https://github.com/alisinabh/enuma",
      start_permanent: Mix.env() == :prod,
      version: "0.1.0"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def elixirc_paths(:test), do: ["lib", "test/support"]
  def elixirc_paths(_), do: ["lib"]

  # Fields for publishing to Hex
  defp package do
    [
      description: "Rust like Enums for Elixir",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/alisinabh/enuma"},
      maintainers: ["Alisina Bahadori"]
    ]
  end

  defp docs do
    [
      # The main page in the docs
      main: "readme",
      extras: ["README.md"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.5", optional: true},
      {:ex_doc, "~> 0.37", only: :dev, runtime: false}
    ]
  end
end
