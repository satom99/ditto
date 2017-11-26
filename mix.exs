defmodule Ditto.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ditto,
      version: "0.1.0",
      elixir: "~> 1.5",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod
    ]
  end

  def application do
    [
      mod: {Ditto, []}
    ]
  end
end
