defmodule ParseTorrent.Mixfile do
  use Mix.Project

  @description """
    Parses a torrent file and returns a map
  """

  def project do
    [app: :parse_torrent,
     version: "0.1.0",
     elixir: "~> 1.2",
     description: @description,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package,
     deps: deps]
  end

  def application do
    []
  end

  defp deps do
    [
      {:earmark, "0.2.1"},
      {:bencode, "0.2.0"},
      {:ex_doc, "0.11.4", only: [:dev]}
    ]
  end

  defp package do
    [
      maintainers: ["Barna Kovacs"],
      licenses: ["UNLICENSE"],
      links: %{"GitHub" => "https://github.com/preciz/parse_torrent"}
    ]
  end
end
