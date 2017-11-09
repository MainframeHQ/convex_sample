use Mix.Config

config :sample_web,
  namespace: SampleWeb

config :sample_web, SampleWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "x8pCe+3U/uDRIJT3sCI0BckrvpVPHScem23Qf33H7FSwD7d3kWJCHVDWYw0YOvOb",
  http: [
    port: 4000,
    dispatch: [
      {:_, [
        {"/api/ws", SampleWeb.Websocket.Handler, []},
        {:_, Plug.Adapters.Cowboy.Handler, {SampleWeb.Endpoint, []}}
      ]}
    ],
  ],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  render_errors: [view: SampleWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: SampleWeb.PubSub,
           adapter: Phoenix.PubSub.PG2],
  watchers: [node: ["node_modules/brunch/bin/brunch", "watch", "--stdin",
                    cd: Path.expand("../assets", __DIR__)]],
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/sample_web/views/.*(ex)$},
      ~r{lib/sample_web/templates/.*(eex)$}
    ]
  ]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :sample_web, :generators,
  context_app: :sample

config :sample_web, SampleWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [node: ["node_modules/brunch/bin/brunch", "watch", "--stdin",
                    cd: Path.expand("../assets", __DIR__)]]
