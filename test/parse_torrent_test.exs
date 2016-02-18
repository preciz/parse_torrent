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

  test "parse torrent with no announce-list" do
    torrent = ParseTorrent.parse("test/torrents/bitlove-intro.torrent")

    expected = %{
      announce: [
        "http://t.bitlove.org/announce"
      ],
      comment: nil,
      created_at: nil,
      created_by: nil,
      files: [
        %{
          length: 19211729,
          name: "bl001-introduction.webm",
          offset: 0,
          path: "bl001-introduction.webm"
        }
      ],
      info_hash: "4cb67059ed6bd08362da625b3ae77f6f4a075705",
      last_piece_length: 337361,
      length: 19211729,
      name: "bl001-introduction.webm",
      piece_length: 1048576,
      pieces: [
        "90a75dcd4e88d287c7ac5599c108f6036c13c4ce",
        "1ef5468bdff9a4466ad4e446477981cb67d07933",
        "1fa911a663451280953edb723e67611957dc0fe1",
        "2abad6066e29c723f01b0908ec30e0e737514a88",
        "55afda8e14a45e7f797eb47b82b2d0a3b2ca5f36",
        "7e1f49593515ca1b93ad01c3ee050e35f04f5c2e",
        "15b9abb123228002cca6a7d88fc9fc99d24583e1",
        "32704a020d2f121bfc612b7627cd92e2b39ad43c",
        "35bebb2888f7143c2966bb4d5f74e0b875825856",
        "6875f4bb1a9fa631ee35bcd7469b1e8ff37d65a2",
        "cbbeeeadc148ed681b699e88a940f796f51c0915",
        "c69121c81d85055678bf198bb29fc9e504ed8c7f",
        "7e3863c6e1c6a8c824569f1cc0950498dceb03c4",
        "ab4e77dade5f54246559c40915b700a4f734cee0",
        "92c47be2d397afbf06a9e9a573a63a3c683d2aa5",
        "01ad212a1495208b7ffbb173ce5782291695652b",
        "3f6233bf4ea3649c7799a1848f06cade97987525",
        "db37c799e45bd02fc25eacc12e18c6c11b4da3fb",
        "4c73df9307b3939fec3cd5f0df179c50a49c6ca3"
      ],
      private: false,
      url_list: [
        "http://spaceboyz.net/~astro/bitlove-show/bl001-introduction.webm"
      ]
    }

    assert torrent == expected
  end

  test "parses empy url-list" do
    torrent = ParseTorrent.parse("test/torrents/leaves-empty-url-list.torrent")

    assert torrent.url_list == []
  end

  test "dedupes announce list" do
    torrent = ParseTorrent.parse("test/torrents/leaves-duplicate-tracker.torrent")

    assert torrent.announce == ["http://tracker.example.com/announce"]
  end

  test "parses url-list for webseed support" do
    torrent = ParseTorrent.parse("test/torrents/leaves-url-list.torrent")

    assert torrent.url_list == [ "http://www2.hn.psu.edu/faculty/jmanis/whitman/leaves-of-grass6x9.pdf" ]
  end
end
