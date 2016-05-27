# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for third-
# party users, it should be done in your mix.exs file.

# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"

# Kernel
config :kernel, :distributed,
  [{:distro, 5000,[:"a@localhost", {:"b@localhost", :"c@localhost"}]}]
config :kernel,
  sync_nodes_mandatory: []
config :kernel,
  sync_nodes_optional: []
config :kernel,
  sync_nodes_timeout: 30000

config :distro, :allowed_boot, (for x <- 2..254, do: "192.168.8.#{x}" |> String.to_atom)

# A logger with default level
config :logger,
  level: :info

# Overwrite the logger level and format in console
config :logger, :console,
  level: :info,
  format: "$date $time $metadata[$level] $message\n"

