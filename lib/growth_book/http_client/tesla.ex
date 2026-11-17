if Code.ensure_loaded?(Tesla) do
  defmodule GrowthBook.HTTPClient.Tesla do
    @moduledoc """
    `GrowthBook.HTTPClient` adapter for [Tesla](https://hex.pm/packages/tesla).

    ## Options

      * `:client` - a prebuilt `Tesla.Client`. When set, `:middleware` and
        `:adapter` are ignored.
      * `:middleware` - middleware list for `Tesla.client/2` (default: `[]`)
      * `:adapter` - Tesla adapter, such as `Tesla.Adapter.Mint`
        (default: Tesla's configured adapter)
      * any other option is passed to `Tesla.get/3`

    If you add a JSON middleware, the decoded body is used as is.
    """

    @behaviour GrowthBook.HTTPClient

    @impl true
    def get(url, opts) do
      {client, opts} = build_client(opts)

      case Tesla.get(client, url, opts) do
        {:ok, %Tesla.Env{status: status, body: body}} ->
          {:ok, %{status: status, body: body}}

        {:error, reason} ->
          {:error, reason}
      end
    end

    # Uses the given client, or builds one from middleware and adapter.
    defp build_client(opts) do
      {client, opts} = Keyword.pop(opts, :client)
      {middleware, opts} = Keyword.pop(opts, :middleware, [])
      {adapter, opts} = Keyword.pop(opts, :adapter)

      {client || Tesla.client(middleware, adapter), opts}
    end
  end
end
