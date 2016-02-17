defmodule ParseTorrent do
  @moduledoc """
    Parses a .torrent file and returns a map

    Usage:
    ParseTorrent.parse("my_path/my_file.torrent")
  """

  def parse(file_path) do
    torrent = File.read!(file_path) |> Bencodex.decode

    torrent
    |> torrent_valid?
    |> do_parse
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

  defp do_parse(torrent) do
    %{
      info_hash: info_hash(torrent),
      name: name(torrent),
      private: private(torrent),
      created_at: created_at(torrent),
      created_by: created_by(torrent),
      announce: announce(torrent),
      files: files(torrent),
      length: sum_length(files(torrent)),
      piece_length: piece_length(torrent),
      last_piece_length: last_piece_length(torrent),
      pieces: pieces(torrent)
    }
  end

  defp info_hash(torrent) do
    torrent["info"]
    |> Bencodex.encode
    |> sha1
    |> Base.encode16
    |> String.downcase
  end

  defp sha1(data) do
    :crypto.hash(:sha, data)
  end

  defp name(torrent) do
    torrent["info"]["name.utf-8"] || torrent["info"]["name"]
  end

  defp private(torrent) do
    !!torrent["info"]["private"]
  end

  defp created_at(torrent) do
    case torrent["creation date"] do
      nil ->
        nil
      _time ->
        epoch = {{1970, 1, 1}, {0, 0, 0}} |> :calendar.datetime_to_gregorian_seconds

        torrent["creation date"]
        |> +(epoch)
        |> :calendar.gregorian_seconds_to_datetime
    end
  end

  defp created_by(torrent) do
    torrent["created by"]
  end

  defp announce(torrent) do
    announce =
      if is_list(torrent["announce-list"]) do
        List.flatten(torrent["announce-list"])
      else
        [torrent["announce"]]
      end

    Enum.uniq(announce)
  end

  defp files(torrent) do
    files = torrent["info"]["files"] || [torrent["info"]]

    files
    |> Enum.with_index
    |> Enum.map(fn {file, i} ->
      parts = [name(torrent)| file["path.utf-8"] || file["path"] || []]

      %{
        path: Enum.reduce(parts, &(&2 <> "/" <> &1)),
        name: List.last(parts),
        length: file["length"],
        offset: offset(files, i)
      }
    end)
  end

  defp offset(_files, 0), do: 0
  defp offset(files, i) do
    files
    |> Enum.slice(0..(i-1))
    |> Enum.map(&(&1["length"]))
    |> Enum.sum
  end

  defp sum_length(files) do
    files
    |> Enum.map(&(&1[:length]))
    |> Enum.sum
  end

  defp piece_length(torrent), do: torrent["info"]["piece length"]

  defp last_piece_length(torrent) do
    last_file = List.last(files(torrent))

    piece_length = piece_length(torrent)

    rem_length = rem((last_file.offset + last_file.length), piece_length)

    case rem_length do
      0 -> piece_length
      _ -> rem_length
    end
  end

  defp pieces(torrent) do
    torrent["info"]["pieces"]
    |> Base.encode16
    |> String.split("", trim: true)
    |> Enum.chunk(40, 40, [])
    |> Enum.map(&Enum.join/1)
    |> Enum.map(&String.downcase/1)
  end

end

defmodule InvalidTorrentError do
  defexception message: "Missing key"
end
