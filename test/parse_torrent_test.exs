defmodule ParseTorrentTest do
  use ExUnit.Case
  doctest ParseTorrent

  test "raises error when torrent file doesn't exist" do
    assert_raise File.Error, fn ->
      ParseTorrent.parse("not-existing.torrent")
    end
  end

  test "raises error when torrent is missing 'name' field" do
    assert_raise InvalidTorrentError, fn ->
      ParseTorrent.parse("test/torrents/leaves-corrupt.torrent")
    end
  end

  test "parse torrent with empty announce-list" do
    torrent = ParseTorrent.parse("test/torrents/leaves-empty-announce-list.torrent")

    assert(torrent.announce == ["udp://tracker.publicbt.com:80/announce"])
  end

  test "parses empy url-list" do
    torrent = ParseTorrent.parse("test/torrents/leaves-empty-url-list.torrent")

    assert torrent.url_list == []
  end

end
