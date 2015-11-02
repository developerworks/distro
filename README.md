Elixir 故障转移和接管
=====================

Elixir 可以运行在主/从, 故障转移/接管模式下. 要使Elixir应用程序能够执行故障转移/接管, Elixir应用程序必须是一个OTP应用程序.

下面来创建一个包含Supervisor的Elixir项目


```
mix new distro --sup
```

修改`distro.ex`添加`logger`模块. 以记录当触发故障转移/接管操作时的日志记录.

```elixir
defmodule Distro do
  use Application
  require Logger
  def start(type, _args) do
    import Supervisor.Spec, warn: false
    Logger.info("Distro application in #{inspect type} mode")
    children = [
      worker(Distro.Worker, [])
    ]
    opts = [strategy: :one_for_one, name: Distro.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```



`Distro.Worker`是一个`GenServer`: 它使用全局名称注册, 假设其运行在集群中的一个节点上, 全局注册让我们不用考虑其实际的运行位置, 只需要提供注册名称就可以访问.

```
defmodule Distro.Worker do
  use GenServer
  require Logger
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
end

```

编译

```
$ mix compile
```

## 应用程序分布

本节阐述了如何把一个应用程序分布到多个节点上

假设应用程序运行在3个节点上, 名称分别为`abc`, `bcd`, `def`. 创建三个配置文件如下:

```
touch config/abc.config
touch config/bcd.config
touch config/def.config
```

配置文件中有3个重要的键值对.

abc.config

```
[
  {logger,[{console,[{format,<<"$date $time $metadata[$level] $message\n">>}]}]},
  {kernel,
    [{distributed, [{'distro', 5000, ['abc@192.168.8.104', {'bcd@192.168.8.104', 'def@192.168.8.104'}]}]},
     {sync_nodes_mandatory, ['bcd@192.168.8.104', 'def@192.168.8.104']},
     {sync_nodes_timeout, 30000}
]}].

```

bcd.config

```
[
  {logger,[{console,[{format,<<"$date $time $metadata[$level] $message\n">>}]}]},
  {kernel,
    [{distributed, [{distro,5000, ['abc@192.168.8.104', {'bcd@192.168.8.104', 'def@192.168.8.104'}]}]},
     {sync_nodes_mandatory, ['abc@192.168.8.104', 'def@192.168.8.104']},
     {sync_nodes_timeout, 30000}
]}].
```

def.config

```
[
  {logger,[{console,[{format,<<"$date $time $metadata[$level] $message\n">>}]}]},
  {kernel,
    [{distributed, [{distro,5000, ['abc@192.168.8.104', {'bcd@192.168.8.104', 'def@192.168.8.104'}]}]},
     {sync_nodes_mandatory, ['abc@192.168.8.104', 'bcd@192.168.8.104']},
     {sync_nodes_timeout, 30000}
]}].

```

在不同的终端自动全部3个节点

```
iex --name abc@192.168.8.104 -pa _build/dev/lib/distro/ebin/ --app distro --erl "-config config/abc"
iex --name bcd@192.168.8.104 -pa _build/dev/lib/distro/ebin/ --app distro --erl "-config config/bcd"
iex --name def@192.168.8.104 -pa _build/dev/lib/distro/ebin/ --app distro --erl "-config config/def"
```


## 验证步骤

1. 终止(Ctrl+C两次)节点`abc@192.168.8.104`后,5秒内会在节点`bcd@192.168.8.104`上重启应用
2. 再次启动节点`abc@192.168.8.104`后,应用在`bcd@192.168.8.104`上停止, 应用被恢复后的`abc@192.168.8.104`节点接管(Takeover)


## 参考资料

1. Elixir Application Failover/Takeover
https://erlangcentral.org/topic/elixir-application-failovertakeover/
