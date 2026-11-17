defmodule GrowthBook.HTTPClientTest do
  use ExUnit.Case, async: false

  alias GrowthBook.HTTPClient
  alias GrowthBook.TestHTTPServer

  @body ~s({"features":{"f":{"defaultValue":true}}})

  describe "resolve/1" do
    setup do
      original = Application.get_env(:growthbook, :http_client)
      Application.delete_env(:growthbook, :http_client)
      on_exit(fn -> Application.put_env(:growthbook, :http_client, original) end)
    end

    test "uses the given module with empty options" do
      assert HTTPClient.resolve(HTTPClient.Req) == {:ok, {HTTPClient.Req, []}}
    end

    test "uses the given {module, opts} tuple" do
      assert HTTPClient.resolve({HTTPClient.Req, retry: :transient}) ==
               {:ok, {HTTPClient.Req, [retry: :transient]}}
    end

    test "falls back to the app env" do
      Application.put_env(:growthbook, :http_client, HTTPClient.Tesla)
      assert HTTPClient.resolve() == {:ok, {HTTPClient.Tesla, []}}
    end

    test "the given client wins over the app env" do
      Application.put_env(:growthbook, :http_client, HTTPClient.Tesla)
      assert HTTPClient.resolve(HTTPClient.Req) == {:ok, {HTTPClient.Req, []}}
    end

    test "auto-detects HTTPoison first when nothing is configured" do
      assert HTTPClient.resolve() == {:ok, {HTTPClient.HTTPoison, []}}
    end
  end

  for adapter <- [HTTPClient.HTTPoison, HTTPClient.Req, HTTPClient.Tesla] do
    describe "#{inspect(adapter)}" do
      test "returns status and raw body" do
        url = TestHTTPServer.start(200, @body)
        assert {:ok, %{status: 200, body: @body}} = unquote(adapter).get(url, [])
      end

      test "returns non-2xx statuses as ok" do
        url = TestHTTPServer.start(500, "oops")
        assert {:ok, %{status: 500, body: "oops"}} = unquote(adapter).get(url, [])
      end

      test "returns an error when the connection fails" do
        # Port 1 is reserved and nothing listens on it.
        assert {:error, _reason} = unquote(adapter).get("http://127.0.0.1:1", [])
      end
    end
  end

  test "the Tesla adapter keeps a body already decoded by middleware" do
    url = TestHTTPServer.start(200, @body)

    assert {:ok, %{status: 200, body: %{"features" => _}}} =
             HTTPClient.Tesla.get(url, middleware: [Tesla.Middleware.JSON])
  end

  test "the repository fetches features through a real adapter" do
    url = TestHTTPServer.start(200, @body)

    start_supervised!(
      {GrowthBook.FeatureRepository,
       client_key: "key", api_host: url, refresh_strategy: :manual, http_client: HTTPClient.Req}
    )

    Process.sleep(200)
    assert GrowthBook.FeatureRepository.get_features() == %{"f" => %{"defaultValue" => true}}
  end
end
