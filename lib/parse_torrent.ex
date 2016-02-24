defmodule ParseTorrent do
  alias ParseTorrent.Error

  @doc """
    Parses a .torrent file and returns a map

    Usage:
    ParseTorrent.parse(data)

    Will raise if binary is invalid.
  """
  def parse(<<"d", _::binary>> = data) do
    torrent = data |> Bencode.decode!

    torrent
    |> torrent_valid?
    |> do_parse
  end

  defp torrent_valid?(torrent) do
    torrent
    |> has_key_or_raise!("info")

    torrent |> Map.get("info")
    |> has_key_or_raise!("name")
    |> has_key_or_raise!("piece length")
    |> has_key_or_raise!("pieces")

    torrent
  end

  defp has_key_or_raise!(torrent, key) do
    Map.has_key?(torrent, key) ||
      raise Error, missing_key: key

    torrent
  end

  defp do_parse(torrent) do
    %{
      info_hash: info_hash(torrent),
      name: name(torrent),
      private: private(torrent),
      created_at: created_at(torrent),
      created_by: created_by(torrent),
      comment: comment(torrent),
      announce: announce(torrent),
      url_list: url_list(torrent),
      files: files(torrent),
      length: sum_length(files(torrent)),
      piece_length: piece_length(torrent),
      last_piece_length: last_piece_length(torrent),
      pieces: pieces(torrent)
    }
  end

  defp info_hash(torrent) do
    torrent["info"]
    |> Bencode.encode!
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

  defp comment(torrent), do: torrent["comment"]

  defp announce(torrent) do
    announce =
      cond do
        is_list(torrent["announce-list"]) ->
          List.flatten(torrent["announce-list"])
        torrent["announce"] ->
          [torrent["announce"]]
        true ->
          []
      end

    Enum.uniq(announce)
  end


  defp url_list(torrent) do
    do_url_list(torrent["url-list"])
  end

  defp do_url_list(nil), do: []
  defp do_url_list(""), do: []
  defp do_url_list(list), do: Enum.uniq(list)

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
