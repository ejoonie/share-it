# frozen_string_literal: true

require "uri"

class PushMessage
  ACTION_VERBS = {
    "created" => "added",
    "updated" => "updated",
    "deleted" => "deleted"
  }.freeze

  attr_reader :title, :body, :data

  def self.for_entry_change(entry:, topic:, actor:, action:)
    verb = ACTION_VERBS.fetch(action.to_s, "added")
    entry_label = entry.title.presence || "No title"
    body = if entry.amount.positive?
      "#{actor.nick_name} #{verb} #{format_amount(entry.amount)} for #{entry_label}"
    else
      "#{actor.nick_name} #{verb} #{entry_label}"
    end

    new(
      title: topic.title,
      body: body,
      data: {
        deeplink: deeplink(entry: entry, topic: topic, action: action)
      }
    )
  end

  def self.format_amount(cents)
    format("$%.2f", cents / 100.0)
  end
  private_class_method :format_amount

  def self.deeplink(entry:, topic:, action:)
    base_url = "https://sharablepiggy.com/topics/#{topic.id}/entries"
    return "#{base_url}/#{entry.id}" unless action.to_s == "deleted"

    occurred_at = (entry.occurred_at || entry.created_at).utc.iso8601
    "#{base_url}?#{URI.encode_www_form(occurred_at: occurred_at)}"
  end
  private_class_method :deeplink

  def initialize(title:, body:, data:)
    @title = title
    @body = body
    @data = data
  end
end
