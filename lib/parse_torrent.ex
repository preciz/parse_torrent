defmodule ParseTorrent do
  alias ParseTorrent.Error

  defstruct(
    info_hash: nil,
    name: nil,
    private: false,
    created_at: nil,
    created_by: nil,
    comment: nil,
    announce: [],
    url_list: [],
    files: [],
    length: nil,
    piece_length: nil,
    last_piece_length: nil,
    pieces: []
  )

  alias ParseTorrent, as: Torrent

  @doc """
    Parses a torrent binary and returns a map.

    Usage:
    ParseTorrent.parse(data)
  """

  def parse(data) do
    try do
      {:ok, parse!(data)}
    rescue
      _e -> :error
    end
  end

  @doc """
    Parses a torrent binary and returns a map.
    Will raise if binary is invalid.

    Usage:
    ParseTorrent.parse!(data)
  """

  def parse!(<<"d", _::binary>> = data) do
    {torrent, info_hash_sha} =
      data |> Bencode.decode_with_info_hash!

    torrent
    |> torrent_valid?
    |> do_parse(info_hash_sha)
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

  defp do_parse(torrent, info_hash_sha) do
    {_torrent, %Torrent{} = parsed} =
      {torrent, %Torrent{}}
      |> parse_info_hash(info_hash_sha)
      |> parse_name
      |> parse_private
      |> parse_created_at
      |> parse_created_by
      |> parse_comment
      |> parse_announce
      |> parse_url_list
      |> parse_files
      |> parse_length
      |> parse_piece_length
      |> parse_last_piece_length
      |> parse_pieces

    parsed
  end

  defp parse_info_hash({torrent, %Torrent{} = parsed}, info_hash_sha) do
    info_hash =
      info_hash_sha
      |> Base.encode16
      |> String.downcase

    {torrent, %Torrent{parsed|info_hash: info_hash}}
  end

  defp sha1(data) do
    :crypto.hash(:sha, data)
  end

  defp parse_name({torrent, %Torrent{} = parsed}) do
    name =
      torrent["info"]["name.utf-8"] || torrent["info"]["name"]

    {torrent, %Torrent{parsed|name: name}}
  end

  defp parse_private({torrent, %Torrent{} = parsed}) do
    private = !!torrent["info"]["private"]

    {torrent, %Torrent{parsed|private: private}}
  end

  defp parse_created_at({torrent, %Torrent{} = parsed}) do
    created_at =
      case torrent["creation date"] do
        nil ->
          nil
        _time ->
          epoch = {{1970, 1, 1}, {0, 0, 0}} |> :calendar.datetime_to_gregorian_seconds

          torrent["creation date"]
          |> +(epoch)
          |> :calendar.gregorian_seconds_to_datetime
      end

    {torrent, %Torrent{parsed|created_at: created_at}}
  end

  defp parse_created_by({torrent, %Torrent{} = parsed}) do
    created_by = torrent["created by"]

    {torrent, %Torrent{parsed|created_by: created_by}}
  end

  defp parse_comment({torrent, %Torrent{} = parsed}) do
    comment = torrent["comment"]

    {torrent, %Torrent{parsed|comment: comment}}
  end

  defp parse_announce({torrent, %Torrent{} = parsed}) do
    announce =
      cond do
        is_list(torrent["announce-list"]) ->
          List.flatten(torrent["announce-list"])
        torrent["announce"] ->
          [torrent["announce"]]
        true ->
          []
      end

    announce = announce |> Enum.uniq

    {torrent, %Torrent{parsed|announce: announce}}
  end


  defp parse_url_list({torrent, %Torrent{} = parsed}) do
    url_list = do_parse_url_list(torrent["url-list"])

    {torrent, %Torrent{parsed|url_list: url_list}}
  end

  defp do_parse_url_list(nil), do: []
  defp do_parse_url_list(""), do: []
  defp do_parse_url_list(list), do: Enum.uniq(list)

  defp parse_files({torrent, %Torrent{} = parsed}) do
    files =
      torrent["info"]["files"] || [torrent["info"]]
      |> do_parse_files(parsed.name)

    {torrent, %Torrent{parsed|files: files}}
  end

  defp do_parse_files(files, name) do
    files
    |> Enum.with_index
    |> Enum.map(fn {file, i} ->
      parts = [name| file["path.utf-8"] || file["path"] || []]

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

  defp parse_length({torrent, %Torrent{} = parsed}) do
    sum_length =
      parsed.files
      |> Enum.map(&(&1[:length]))
      |> Enum.sum

    {torrent, %Torrent{parsed|length: sum_length}}
  end

  defp parse_piece_length({torrent, %Torrent{} = parsed}) do
    piece_length = torrent["info"]["piece length"]

    {torrent, %Torrent{parsed|piece_length: piece_length}}
  end

  defp parse_last_piece_length({torrent, %Torrent{} = parsed}) do
    last_file =
      parsed.files
      |> List.last

    piece_length = parsed.piece_length

    rem_length =
      rem((last_file.offset + last_file.length), piece_length)

    last_piece_length =
      case rem_length do
        0 -> piece_length
        _ -> rem_length
      end

    {torrent, %Torrent{parsed|last_piece_length: last_piece_length}}
  end

  defp parse_pieces({torrent, %Torrent{} = parsed}) do
    pieces =
      torrent["info"]["pieces"]
      |> Base.encode16
      |> String.split("", trim: true)
      |> Enum.chunk(40, 40, [])
      |> Enum.map(&Enum.join/1)
      |> Enum.map(&String.downcase/1)

    {torrent, %Torrent{parsed|pieces: pieces}}
  end
end
