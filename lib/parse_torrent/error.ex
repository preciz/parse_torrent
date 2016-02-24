defmodule ParseTorrent.Error do
  defexception(missing_key: "")

  def message(exception) do
    "Missing required key: #{exception.missing_key}"
  end
end
