defmodule GrowthBook.TestHTTPServer do
  @moduledoc """
  Minimal local HTTP server for testing the HTTP client adapters.

  Answers every request with the given status and body, then closes the connection.
  """

  @doc "Starts the server on a random port and returns the base URL."
  @spec start(non_neg_integer(), binary()) :: String.t()
  def start(status, body) do
    {:ok, socket} =
      :gen_tcp.listen(0, [:binary, packet: :raw, active: false, reuseaddr: true])

    {:ok, port} = :inet.port(socket)
    spawn_link(fn -> accept_loop(socket, status, body) end)
    "http://127.0.0.1:#{port}"
  end

  # Serves connections one at a time until the test process exits.
  defp accept_loop(socket, status, body) do
    {:ok, conn} = :gen_tcp.accept(socket)
    {:ok, _request} = :gen_tcp.recv(conn, 0, 5_000)

    response =
      "HTTP/1.1 #{status} Status\r\n" <>
        "content-type: application/json\r\n" <>
        "content-length: #{byte_size(body)}\r\n" <>
        "connection: close\r\n\r\n" <> body

    :ok = :gen_tcp.send(conn, response)
    :gen_tcp.close(conn)
    accept_loop(socket, status, body)
  end
end
