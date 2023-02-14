# SPDX-License-Identifier: AGPL-3.0-only
defmodule ActivityPubWeb.ObjectView do
  use ActivityPubWeb, :view
  import Untangle
  alias ActivityPub.Utils
  alias ActivityPubWeb.Transmogrifier
  alias ActivityPub.Object

  def render("object.json", %{object: object}) do
    {:ok, additional} =
      object
      # |> debug
      |> Transmogrifier.prepare_outgoing()

    # |> debug

    Map.merge(Utils.make_json_ld_header(), additional)
  end

  def render("outbox.json", %{actor: actor, page: page}) do
    outbox = Object.get_outbox_for_actor(actor, page)

    total = length(outbox)

    collection(outbox, "#{actor.ap_id}/outbox", page, total)
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("outbox.json", %{actor: actor}) do
    outbox = Object.get_outbox_for_actor(actor)

    total = length(outbox)

    %{
      "id" => "#{actor.ap_id}/outbox",
      "type" => "Collection",
      "first" => collection(outbox, "#{actor.ap_id}/outbox", 1, total),
      "totalItems" => total
    }
    |> Map.merge(Utils.make_json_ld_header())
  end

  # only for testing purposes
  def render("outbox.json", %{outbox: :shared_outbox} = params) do
    instance = ActivityPubWeb.base_url()
    page = params[:page] || 1
    outbox = Object.get_outbox_for_instance()

    total = length(outbox)

    %{
      "id" => "#{instance}/shared_outbox",
      "type" => "Collection",
      "first" => collection(outbox, "#{instance}/shared_outbox", page, total),
      "totalItems" => total
    }
    |> Map.merge(Utils.make_json_ld_header())
  end

  def collection(collection, iri, page, total \\ nil) do
    offset = (page - 1) * 10

    items =
      collection
      |> debug()
      |> Enum.map(fn object ->
        render("object.json", %{object: object})
      end)
      |> debug()

    total = total || length(collection)

    map = %{
      "id" => "#{iri}?page=#{page}",
      "type" => "CollectionPage",
      "partOf" => iri,
      "totalItems" => total,
      "orderedItems" => items
    }

    if offset < total do
      Map.put(map, "next", "#{iri}?page=#{page + 1}")
    else
      map
    end
  end
end
