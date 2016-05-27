
defmodule Distro.Worker do
	use GenServer
  require Logger

  @on_load :load_check

  def start_link do
    GenServer.start_link(__MODULE__, [], name: {:global, __MODULE__})
  end

  def init([]) do
    {:ok, [], 1000}
  end

  def handle_info(:timeout, state) do
    Logger.debug "timeout"
    {:noreply, state, 1000}
  end

  def load_check do
    Logger.debug "Module #{__MODULE__} is loaded."
  end
end
