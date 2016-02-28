defmodule ParseTorrentTest do
  use ExUnit.Case
  doctest ParseTorrent

  test "`parse` returns `:error` when torrent is missing 'name' field" do
    torrent = File.read!("test/torrents/leaves-corrupt.torrent")
    |> ParseTorrent.parse

    assert :error == torrent
  end

  test "`parse!` raises error when torrent is missing 'name' field" do
    assert_raise ParseTorrent.Error, fn ->
      File.read!("test/torrents/leaves-corrupt.torrent")
      |> ParseTorrent.parse!
    end
  end

  test "`parse` returns tuple with `:ok`" do
    torrent = File.read!("test/torrents/leaves.torrent")
    |> ParseTorrent.parse

    assert {:ok, _} = torrent
  end

  test "parse torrent with empty announce-list" do
    torrent = File.read!("test/torrents/leaves-empty-announce-list.torrent")
    |> ParseTorrent.parse!

    assert(torrent.announce == ["udp://tracker.publicbt.com:80/announce"])
  end

  test "parse torrent with no announce-list" do
    torrent = File.read!("test/torrents/bitlove-intro.torrent")
    |> ParseTorrent.parse!

    expected = %ParseTorrent{
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
    torrent = File.read!("test/torrents/leaves-empty-url-list.torrent")
    |> ParseTorrent.parse!

    assert torrent.url_list == []
  end

  test "dedupes announce list" do
    torrent = File.read!("test/torrents/leaves-duplicate-tracker.torrent")
    |> ParseTorrent.parse!

    assert torrent.announce == ["http://tracker.example.com/announce"]
  end

  test "parses url-list for webseed support" do
    torrent = File.read!("test/torrents/leaves-url-list.torrent")
    |> ParseTorrent.parse!

    assert torrent.url_list == [ "http://www2.hn.psu.edu/faculty/jmanis/whitman/leaves-of-grass6x9.pdf" ]
  end

  test "parses single file torrent" do
    leaves_parsed = %ParseTorrent{
      info_hash: "d2474e86c95b19b8bcfdb92bc12c9d44667cfa36",
      name: "Leaves of Grass by Walt Whitman.epub",
      created_by: "uTorrent/3300",
      created_at: {{2013, 8, 1}, {13, 27, 46}},
      comment: nil,
      private: false,
      announce: [],
      url_list: [],
      files: [
        %{
          path: "Leaves of Grass by Walt Whitman.epub",
          name: "Leaves of Grass by Walt Whitman.epub",
          length: 362017,
          offset: 0
        }
      ],
      length: 362017,
      piece_length: 16384,
      last_piece_length: 1569,
      pieces: [
        "1f9c3f59beec079715ec53324bde8569e4a0b4eb",
        "ec42307d4ce5557b5d3964c5ef55d354cf4a6ecc",
        "7bf1bcaf79d11fa5e0be06593c8faafc0c2ba2cf",
        "76d71c5b01526b23007f9e9929beafc5151e6511",
        "0931a1b44c21bf1e68b9138f90495e690dbc55f5",
        "72e4c2944cbacf26e6b3ae8a7229d88aafa05f61",
        "eaae6abf3f07cb6db9677cc6aded4dd3985e4586",
        "27567fa7639f065f71b18954304aca6366729e0b",
        "4773d77ae80caa96a524804dfe4b9bd3deaef999",
        "c9dd51027467519d5eb2561ae2cc01467de5f643",
        "0a60bcba24797692efa8770d23df0a830d91cb35",
        "b3407a88baa0590dc8c9aa6a120f274367dcd867",
        "e88e8338c572a06e3c801b29f519df532b3e76f6",
        "70cf6aee53107f3d39378483f69cf80fa568b1ea",
        "c53b506159e988d8bc16922d125d77d803d652c3",
        "ca3070c16eed9172ab506d20e522ea3f1ab674b3",
        "f923d76fe8f44ff32e372c3b376564c6fb5f0dbe",
        "52164f03629fd1322636babb2c014b7dae582da4",
        "1363965261e6ce12b43701f0a8c9ed1520a70eba",
        "004400a267765f6d3dd5c7beb5bd3c75f3df2a54",
        "560a61801147fa4ec7cf568e703acb04e5610a4d",
        "56dcc242d03293e9446cf5e457d8eb3d9588fd90",
        "c698de9b0dad92980906c026d8c1408fa08fe4ec"
      ]
    }

    torrent = File.read!("test/torrents/leaves.torrent")
    |> ParseTorrent.parse!

    assert torrent == leaves_parsed
  end
end
