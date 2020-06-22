defmodule ActivityPub.Workers.PublisherWorker do
  alias ActivityPub.Object
  alias ActivityPubWeb.Federator

  use ActivityPub.Workers.WorkerHelper, queue: "federator_outgoing"

  @impl Oban.Worker
  def perform(%{"op" => "publish", "activity_id" => activity_id}, _job) do
    activity = Object.get_by_id(activity_id)
    Federator.perform(:publish, activity)
  end

  def perform(%{"op" => "publish_one", "module" => module_name, "params" => params}, _job) do
    params = Map.new(params, fn {k, v} -> {String.to_atom(k), v} end)
    Federator.perform(:publish_one, String.to_atom(module_name), params)
  end
end
