# ditto

*ditto* provides an easy way of distributing and identifying processes
across connected nodes by using [mnesia](http://erlang.org/doc/man/mnesia.html).

##### Example
```elixir
# config.exs
config :ditto, :nodes, [
  "one@localhost",
  "two@localhost",
  # ...
]

# terminal
>> iex --sname one@localhost -S mix
>> {:ok, pid} = GenServer.start_link Example, []
>> Ditto.register(:magic, pid)

>> iex --sname two@localhost -S mix
>> row = Ditto.find(:magic)
>> pid = row[:pid]
>> GenServer.cast pid, {:print, "Hello world!"}
```
