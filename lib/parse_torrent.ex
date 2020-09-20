defmodule ParseTorrent do
  @moduledoc """
  A module for convenient .torrent parsing.
  """

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

  alias ParseTorrent.Error
  alias ParseTorrent, as: Torrent

  @doc """
  Parses a torrent binary and returns a map.

  ## Examples

      data = File.read!("test/torrents/leaves.torrent")
      {:ok, torrent_map} = ParseTorrent.parse(data)

  """

  @spec parse(binary) :: {:ok, map} | :error
  def parse(data) do
    {:ok, parse!(data)}
    rescue
      _e -> :error
  end

  @doc """
  Parses a torrent binary and returns a map. Will raise if binary is invalid.

  ## Examples

      data = File.read!("test/torrents/leaves.torrent")
      torrent_map = ParseTorrent.parse!(data)

  """

  @spec parse!(binary) :: map | no_return
  def parse!(<<"d", _::binary>> = data) do
    {torrent, info_hash_sha} = data |> Bencode.decode_with_info_hash!()

    torrent
    |> torrent_valid?
    |> do_parse
    |> parse_info_hash(info_hash_sha)
  end

  defp torrent_valid?(torrent) do
    torrent
    |> has_key_or_raise!("info")

    torrent
    |> Map.get("info")
    |> has_key_or_raise!("name")
    |> has_key_or_raise!("piece length")
    |> has_key_or_raise!("pieces")

    torrent
  end

  defp has_key_or_raise!(torrent, key) do
    case Map.has_key?(torrent, key) do
      true -> torrent
      _ -> raise Error, missing_key: key
    end
  end

  defp do_parse(torrent) do
    {_torrent, %Torrent{} = parsed} =
      {torrent, %Torrent{}}
      |> parse(:name, &parse_name/1)
      |> parse(:private, &parse_private/1)
      |> parse(:created_at, &parse_created_at/1)
      |> parse(:created_by, &parse_created_by/1)
      |> parse(:comment, &parse_comment/1)
      |> parse(:announce, &parse_announce/1)
      |> parse(:url_list, &parse_url_list/1)
      |> parse(:files, &parse_files/1)
      |> parse(:length, &parse_length/1)
      |> parse(:piece_length, &parse_piece_length/1)
      |> parse(:last_piece_length, &parse_last_piece_length/1)
      |> parse(:pieces, &parse_pieces/1)

    parsed
  end

  defp parse({torrent, %Torrent{} = parsed}, key, func) do
    parsed_value = func.({torrent, parsed})

    {torrent, Map.put(parsed, key, parsed_value)}
  end

  defp parse_info_hash(%Torrent{} = parsed, info_hash_sha) do
    info_hash =
      info_hash_sha
      |> Base.encode16()
      |> String.downcase()

    %Torrent{parsed | info_hash: info_hash}
  end

  defp parse_name({torrent, _}) do
    torrent["info"]["name.utf-8"] || torrent["info"]["name"]
  end

  defp parse_private({torrent, _}) do
    !!torrent["info"]["private"]
  end

  defp parse_created_at({torrent, _}) do
    case torrent["creation date"] do
      nil ->
        nil

      _time ->
        epoch = {{1970, 1, 1}, {0, 0, 0}} |> :calendar.datetime_to_gregorian_seconds()

        (torrent["creation date"] + epoch) |> :calendar.gregorian_seconds_to_datetime()
    end
  end

  defp parse_created_by({torrent, _parsed}) do
    torrent["created by"]
  end

  defp parse_comment({torrent, _parsed}) do
    torrent["comment"]
  end

  defp parse_announce({torrent, _parsed}) do
    announce =
      cond do
        is_list(torrent["announce-list"]) ->
          List.flatten(torrent["announce-list"])

        torrent["announce"] ->
          [torrent["announce"]]

        true ->
          []
      end

    announce |> Enum.uniq()
  end

  defp parse_url_list({torrent, _parsed}) do
    do_parse_url_list(torrent["url-list"])
  end

  defp do_parse_url_list(nil), do: []
  defp do_parse_url_list(""), do: []
  defp do_parse_url_list(list), do: Enum.uniq(list)

  defp parse_files({torrent, %Torrent{} = parsed}) do
    torrent["info"]["files"] ||
      [torrent["info"]]
      |> do_parse_files(parsed.name)
  end

  defp do_parse_files(files, name) do
    files
    |> Enum.with_index()
    |> Enum.map(fn {file, i} ->
      parts = [name | file["path.utf-8"] || file["path"] || []]

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
    |> Enum.slice(0..(i - 1))
    |> Enum.map(& &1["length"])
    |> Enum.sum()
  end

  defp parse_length({_torrent, %Torrent{} = parsed}) do
    parsed.files
    |> Enum.map(& &1[:length])
    |> Enum.sum()
  end

  defp parse_piece_length({torrent, _parsed}) do
    torrent["info"]["piece length"]
  end

  defp parse_last_piece_length({_torrent, %Torrent{} = parsed}) do
    last_file =
      parsed.files
      |> List.last()

    piece_length = parsed.piece_length

    rem_length = rem(last_file.offset + last_file.length, piece_length)

    case rem_length do
      0 -> piece_length
      _ -> rem_length
    end
  end

  defp parse_pieces({torrent, _parsed}) do
    torrent["info"]["pieces"]
    |> Base.encode16()
    |> String.split("", trim: true)
    |> Enum.chunk_every(40, 40, [])
    |> Enum.map(&Enum.join/1)
    |> Enum.map(&String.downcase/1)
  end
end
