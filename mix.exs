defmodule ParseTorrent.Mixfile do
  use Mix.Project

  @description """
  A module for convenient .torrent parsing
  """

  @version "0.3.2"
  @github "https://github.com/preciz/parse_torrent"

  def project do
    [
      app: :parse_torrent,
      version: @version,
      elixir: "~> 1.7",
      description: @description,
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "ParseTorrent",
      docs: docs(),
      package: package()
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:bencode, "0.3.2"},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.28.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Barna Kovacs"],
      licenses: ["MIT"],
      links: %{"GitHub" => @github}
    ]
  end

  def docs do
    [
      main: "ParseTorrent",
      source_ref: "v#{@version}",
      source_url: @github
    ]
  end
end
