if Code.ensure_loaded?(Req) do
  defmodule GrowthBook.HTTPClient.Req do
    @moduledoc """
    `GrowthBook.HTTPClient` adapter for [Req](https://hex.pm/packages/req).

    ## Options

    All options are passed to `Req.get/2`. The adapter sets these defaults,
    which you can override:

      * `decode_body: false` - the SDK decodes the JSON itself
      * `retry: false` - the repository already refreshes on its own schedule,
        and retries would block it
    """

    @behaviour GrowthBook.HTTPClient

    @defaults [decode_body: false, retry: false]

    @impl true
    def get(url, opts) do
      case Req.get(url, Keyword.merge(@defaults, opts)) do
        {:ok, %Req.Response{status: status, body: body}} ->
          {:ok, %{status: status, body: body}}

        {:error, %{reason: reason}} ->
          {:error, reason}

        {:error, error} ->
          {:error, error}
      end
    end
  end
end
