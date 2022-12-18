defmodule MemeCacheBot.Telemetry do
  def attach_all() do
    attach_many("ex_gram", [[:ex_gram, :dispatcher, :stop], [:ex_gram, :dispatcher, :exception]])
  end

  def attach_many(handler_id, event_names) do
    :telemetry.attach_many(handler_id, event_names, &MemeCacheBot.Telemetry.handle_event/4, nil)
  end

  def handle_event(event_name, measurements, metadata, _config) do
    IO.inspect(event_name, label: "event_name")
    IO.inspect(measurements, label: "measurements")
    IO.inspect(metadata, label: "metadata")
  end
end
