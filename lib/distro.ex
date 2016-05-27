defmodule Distro do
  use Application
  require Logger

  def start(type, _args) do
    import Supervisor.Spec, warn: false
    Logger.info("Distro application started in #{inspect type} mode")

    children = [
      worker(Distro.Worker, [])
    ]

    opts = [strategy: :one_for_one, name: Distro.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
