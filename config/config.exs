use Mix.Config

import_config "../apps/*/config/config.exs"

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :logger, level: :debug

config :phoenix, :stacktrace_depth, 20

