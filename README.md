Elixir 故障转移和接管
=====================

Elixir 可以运行在主/从, 故障转移/接管模式下. 要使Elixir应用程序能够执行故障转移/接管, Elixir应用程序必须是一个OTP应用程序.

下面来创建一个包含Supervisor的Elixir项目


```
mix new distro --sup
```

修改`distro.ex`添加`logger`模块. 以记录当触发故障转移/接管操作时的日志记录.

```
defmodule Distro do
  use Application
  require Logger
  #See http://elixir-lang.org/docs/stable/elixir/Application.html
  #for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    Logger.info("Distro application in #{inspect _type} mode")
    children = [
      #Define workers and child supervisors to be supervised
      worker(Distro.DistroCal, [])
    ]
    #See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    #for other strategies and supported options
    opts = [strategy: :one_for_one, name: Distro.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

`DistroCal`位于`distro`子目录

```
$ mkdir lib/distro
$ touch lib/distro/distro_cal.ex
```

`DistroCal`是一个`GenServer`: 它使用全局名称注册, 假设其运行在集群中的一个节点上, 全局注册让我们不用考虑其实际的运行位置, 只需要提供注册名称就可以反问.

```
defmodule Distro.DistroCal do
    use GenServer
    require Logger
    def start_link do
        GenServer.start_link(__MODULE__, [], name: {:global, __MODULE__})
    end
    def add(x,y) do
        GenServer.call({:global, __MODULE__}, {:cal, x, y})
    end
    def handle_call({:cal, x, y}, _from, state) do
        {:reply, x + y, state}
    end
end
```

编译和运行

```
$ mix compile
$ iex --sname -pa _build/dev/lib/distro/ebin/ --app distro
iex(abc@44adb2a6d305)1>
```

## 应用程序分布

本节阐述了如何把一个应用程序分布到多个节点上

假设应用程序运行在3个节点上, 名称分别为`a`, `b`, `c`. 创建三个配置文件如下:

```
touch config/a.config
touch config/b.config
touch config/c.config
```

配置文件中有3个重要的键值对.

`sync_nodes_timeout` -
`sync_nodes_mandatory` -
`distributed` -


a.config

```
[{kernel,
	[
	    {
	        distributed,
	        [{
	            'distro', 5000, [
	                'abc@192.168.8.104',
	                {'bcd@192.168.8.104', 'def@192.168.8.104'}
	            ]
            }]
        },
        {sync_nodes_mandatory, ['bcd@192.168.8.104', 'def@192.168.8.104']},
        {sync_nodes_timeout, 30000}
    ]
}].
```

b.config

```
[{kernel,
[
    {
        distributed,
        [
            {distro,5000, [
                'abc@192.168.8.104',
                {'bcd@192.168.8.104', 'def@192.168.8.104'}
                ]
            }
        ]
    },
    {sync_nodes_mandatory, ['abc@192.168.8.104', 'def@192.168.8.104']},
    {sync_nodes_timeout, 30000}
]}].
```

c.config

```
[{kernel,
	[
	    {
	        distributed, [
	        {
	            distro,5000, [
	                'abc@192.168.8.104',
	                {'bcd@192.168.8.104', 'def@192.168.8.104'}
	            ]
            }
        ]},
        {sync_nodes_mandatory, ['abc@192.168.8.104', 'bcd@192.168.8.104']},
        {sync_nodes_timeout, 30000}
    ]
}].
```

在不同的终端自动全部3个节点

```
iex --name abc@192.168.8.104 -pa _build/dev/lib/distro/ebin/ --app distro --erl "-config config/abc"
iex --name bcd@192.168.8.104 -pa _build/dev/lib/distro/ebin/ --app distro --erl "-config config/bcd"
iex --name def@192.168.8.104 -pa _build/dev/lib/distro/ebin/ --app distro --erl "-config config/def"
```


## 参考资料

1. Elixir Application Failover/Takeover
https://erlangcentral.org/topic/elixir-application-failovertakeover/
