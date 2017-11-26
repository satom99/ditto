defmodule Ditto.Hook do
  defmacro __using__(_opts) do
    quote do
      def get(key) do
        with %{pid: pid} <- Ditto.find(key),
            true <- Process.alive?(pid)
        do pid
        else
          _ -> Ditto.spin(__MODULE__, key)
        end
      end
    end
  end
end
