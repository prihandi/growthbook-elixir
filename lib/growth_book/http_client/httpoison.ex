if Code.ensure_loaded?(HTTPoison) do
  defmodule GrowthBook.HTTPClient.HTTPoison do
    @moduledoc """
    `GrowthBook.HTTPClient` adapter for [HTTPoison](https://hex.pm/packages/httpoison).

    ## Options

      * `:headers` - request headers (default: `[]`)
      * any other option is passed to `HTTPoison.get/3`, such as `:recv_timeout`
    """

    @behaviour GrowthBook.HTTPClient

    @impl true
    def get(url, opts) do
      {headers, opts} = Keyword.pop(opts, :headers, [])

      case HTTPoison.get(url, headers, opts) do
        {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
          {:ok, %{status: status, body: body}}

        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, reason}
      end
    end
  end
end
