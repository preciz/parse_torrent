defmodule ParseTorrent do
  @moduledoc """
    Parses a .torrent file and returns a map

    Usage:
    ParseTorrent.parse("my_path/my_file.torrent")
  """

  def parse(file_path) do
    torrent = File.read!(file_path)

    torrent
    |> Bencodex.decode
    |> torrent_valid?
  end

  defp torrent_valid?(torrent) do
    import Map, only: [get: 2, fetch!: 2]

    try do
      torrent |> fetch!("info")
      torrent |> get("info") |> fetch!("name")
      torrent |> get("info") |> fetch!("piece length")
      torrent |> get("info") |> fetch!("pieces")
    rescue
      _ -> raise(InvalidTorrentError)
    end

    torrent
  end
end

defmodule InvalidTorrentError do
  defexception message: "Missing key"
end
