defmodule ParseTorrent.Mixfile do
  use Mix.Project

  @description """
    Parses a .torrent file and returns a map
  """

  @version "0.3.1"

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

      package: package(),
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:bencode, "0.3.2"},
      {:ex_doc, "~> 0.20.2", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Barna Kovacs"],
      licenses: ["UNLICENSE"],
      links: %{"GitHub" => "https://github.com/preciz/parse_torrent"}
    ]
  end

  def docs do
    [
      main: "ParseTorrent",
      source_ref: "v#{@version}",
      source_url: "https://github.com/preciz/parse_torrent",
    ]
  end
end
