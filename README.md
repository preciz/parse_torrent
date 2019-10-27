# ParseTorrent
[![Travis](https://img.shields.io/travis/preciz/parse_torrent.svg?style=flat-square)](https://travis-ci.org/preciz/parse_torrent)

ParseTorrent parses a .torrent file and returns a map

## Installation

Add parse_torrent to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:parse_torrent, "~> 0.3"}
  ]
end
```

## Usage
`parse/1` will return a 2-tuple with `:ok` or return `:error` if torrent is invalid.

```elixir
data = File.read!("mypath/myfile.torrent")
ParseTorrent.parse(data)
```

`parse!/1` will return a map or raise if torrent is invalid.

```elixir
ParseTorrent.parse!(data)
```

## Credit

Based on [parse-torrent-file](https://github.com/feross/parse-torrent-file) by [feross](https://github.com/feross).

## License

ParseTorrent is [MIT licensed](LICENSE).
