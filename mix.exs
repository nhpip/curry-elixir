defmodule Curry.MixProject do
  use Mix.Project

  def project do
    [
      app: :curry_elixir,
      version: "1.0.0",
      elixir: "~> 1.10",
      description: description(),
      package: package(),
      name: "Curry Elixir",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [ ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:variadic, github: "nhpip/variadic-elixir"},
     {:ex_doc, "~> 0.28.4", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "A simple module to do currying and partial application using Variadic functions to start partial evaluation"
  end

  defp package() do
    [
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/nhpip/curry-elixir"}
    ]
  end
end
