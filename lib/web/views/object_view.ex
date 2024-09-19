# SPDX-License-Identifier: AGPL-3.0-only
defmodule ActivityPub.Web.ObjectView do
  use ActivityPub.Web, :view
  import Untangle
  use Arrows
  alias ActivityPub.Utils
  alias ActivityPub.Federator.Transformer
  alias ActivityPub.Object

  def render("object.json", %{object: object}) do
    object
    # |> debug
    |> Transformer.prepare_outgoing()
    ~> Transformer.preserve_privacy_of_outgoing()
  end

  def render("outbox.json", %{actor: actor, page: page}) when not is_nil(page) do
    outbox = Object.get_outbox_for_actor(actor, page)
    total = Object.get_outbox_for_actor_count(actor)

    collection(outbox, "#{actor.ap_id}/outbox", page, total)
    |> Map.merge(Utils.make_json_ld_header(:object))
  end

  def render("outbox.json", %{actor: actor}) do
    total = Object.get_outbox_for_actor_count(actor)

    %{
      "id" => "#{actor.ap_id}/outbox",
      "type" => "OrderedCollection",
      # "first" => collection(outbox, "#{actor.ap_id}/outbox", 1, total),
      "first" => "#{actor.ap_id}/outbox?page=true",
      "totalItems" => total
    }
    |> Map.merge(Utils.make_json_ld_header(:object))
  end

  # only for testing purposes
  def render("outbox.json", %{outbox: :shared_outbox, page: page}) when not is_nil(page) do
    ap_base_url = Utils.ap_base_url()
    outbox = Object.get_outbox_for_instance(page)
    total = Object.get_outbox_for_instance_count()

    collection(outbox, "#{ap_base_url}/shared_outbox", page, total)
    |> Map.merge(Utils.make_json_ld_header(:object))
  end

  def render("outbox.json", %{outbox: :shared_outbox}) do
    ap_base_url = Utils.ap_base_url()
    total = Object.get_outbox_for_instance_count()

    %{
      "id" => "#{ap_base_url}/shared_outbox",
      "type" => "OrderedCollection",
      "first" => "#{ap_base_url}/shared_outbox?page=true",
      "totalItems" => total
    }
    |> Map.merge(Utils.make_json_ld_header(:object))
  end

  def render("inbox.json", %{inbox: :shared_inbox, page: page}) when not is_nil(page) do
    ap_base_url = Utils.ap_base_url()
    inbox = Object.get_inbox(:shared, page)
    total = Object.get_inbox_count(:shared)

    collection(inbox, "#{ap_base_url}/shared_outbox", page, total)
    |> Map.merge(Utils.make_json_ld_header(:object))
  end

  def render("inbox.json", %{inbox: :shared_inbox}) do
    ap_base_url = Utils.ap_base_url()

    total = Object.get_inbox_count(:shared)

    %{
      "id" => "#{ap_base_url}/shared_inbox",
      "type" => "OrderedCollection",
      # "first" => collection(outbox, "#{ap_base_url}/shared_inbox", page, total),
      "first" => "#{ap_base_url}/shared_inbox?page=true",
      "totalItems" => total
    }
    |> Map.merge(Utils.make_json_ld_header(:object))
  end

  def collection(collection, iri, page, total) do
    items =
      collection
      |> debug()
      |> Enum.map(fn object ->
        render("object.json", %{object: object})
      end)

    map = %{
      "id" => "#{iri}?page=#{page}",
      "type" => "CollectionPage",
      "partOf" => iri,
      "totalItems" => total,
      "orderedItems" => items
    }

    if page * 10 < total do
      Map.put(map, "next", "#{iri}?page=#{page + 1}")
    else
      map
    end
    |> debug()
  end
end
