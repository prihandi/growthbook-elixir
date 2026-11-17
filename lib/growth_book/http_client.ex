defmodule GrowthBook.HTTPClient do
  @moduledoc """
  Behaviour for the HTTP client used to fetch features from the GrowthBook API.

  The SDK ships adapters for three clients. Add the one you want to your deps:

    * `GrowthBook.HTTPClient.HTTPoison` - needs `{:httpoison, "~> 3.0"}`
    * `GrowthBook.HTTPClient.Req` - needs `{:req, "~> 0.5"}`
    * `GrowthBook.HTTPClient.Tesla` - needs `{:tesla, "~> 1.4"}`

  ## Choosing a client

  Pass `:http_client` to `GrowthBook.init/1`, or set it in your config:

      config :growthbook, http_client: GrowthBook.HTTPClient.Req

  Use a `{module, opts}` tuple to pass options to the adapter:

      config :growthbook,
        http_client: {GrowthBook.HTTPClient.Req, receive_timeout: 5_000}

  If nothing is set, the first available client is used, in this order:
  HTTPoison, Req, Tesla.

  ## Custom clients

  Any module that implements `c:get/2` can be used, for example a test mock.
  """

  @typedoc "A normalized HTTP response."
  @type response :: %{status: non_neg_integer(), body: binary() | map()}

  @typedoc "A client module, or a client module with its options."
  @type spec :: module() | {module(), keyword()}

  @doc """
  Sends a GET request to `url`.

  Returns the status and the raw body. Non-2xx statuses are still `{:ok, response}`.
  """
  @callback get(url :: String.t(), opts :: keyword()) :: {:ok, response()} | {:error, term()}

  # Adapters tried in order when no client is configured.
  @auto_detect [
    {HTTPoison, GrowthBook.HTTPClient.HTTPoison},
    {Req, GrowthBook.HTTPClient.Req},
    {Tesla, GrowthBook.HTTPClient.Tesla}
  ]

  @doc """
  Resolves the client to use as a `{module, opts}` tuple.

  Uses `configured` if given, then the `:http_client` app env, then auto-detection.
  Returns `{:error, :no_http_client}` when no client is available.
  """
  @spec resolve(spec() | nil) :: {:ok, {module(), keyword()}} | {:error, :no_http_client}
  def resolve(configured \\ nil) do
    case configured || Application.get_env(:growthbook, :http_client) do
      nil -> auto_detect()
      {module, opts} when is_atom(module) and is_list(opts) -> {:ok, {module, opts}}
      module when is_atom(module) -> {:ok, {module, []}}
    end
  end

  @doc "Sends a GET request with a resolved `{module, opts}` client."
  @spec get(String.t(), {module(), keyword()}) :: {:ok, response()} | {:error, term()}
  def get(url, {module, opts}), do: module.get(url, opts)

  defp auto_detect do
    Enum.find_value(@auto_detect, {:error, :no_http_client}, fn {dep, adapter} ->
      if Code.ensure_loaded?(dep) and Code.ensure_loaded?(adapter), do: {:ok, {adapter, []}}
    end)
  end
end
