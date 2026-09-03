# Dev task for triggering real push notifications against a simulator/device.
# Runs the same flow as the CRUD actions in entries_api.rb (mark_entry_read!,
# soft_delete!, NotifyTopicChange), so notifications sent here match what a
# real app interaction would send.
namespace :push do
  desc "List topic/actor combos that can send a push (based on users with a registered device token)"
  task list: :environment do
    device_tokens = DeviceToken.includes(:user).to_a
    if device_tokens.empty?
      abort("No device tokens registered - enable notifications in the app first")
    end

    device_tokens.each do |dt|
      recipient = dt.user
      puts "recipient: #{recipient.nick_name} (user##{recipient.id}, #{dt.platform})"

      follows = recipient.topic_follows.where(notifications_enabled: true)
      if follows.none?
        puts "  (no subscribed topics, or all muted)"
        next
      end

      follows.each do |follow|
        topic = Topic.unscoped.find(follow.topic_id)
        actor_candidates = TopicFollow.where(topic_id: topic.id).where.not(user_id: recipient.id).map(&:user)
        next if actor_candidates.empty?

        actors = actor_candidates.map { |u| "#{u.nick_name}(#{u.id})" }.join(", ")
        puts "  TOPIC_ID=#{topic.id} \"#{topic.title}\" / ACTOR_ID candidates: #{actors}"
      end
    end
  end

  desc <<~DESC
    Create/update/delete an entry to trigger a real push (check candidates with rake push:list first).
      RECIPIENT_ID=<id> [ACTION=created|updated|deleted] [TITLE=..] [AMOUNT=..] rake push:send
      TOPIC_ID=<id> ACTOR_ID=<id> [ACTION=created|updated|deleted] [TITLE=..] [AMOUNT=..] rake push:send
    With RECIPIENT_ID, a subscribed topic and another member are auto-picked for that recipient.
    If all IDs are omitted, the first eligible recipient is used.
  DESC
  task send: :environment do
    action = ENV.fetch("ACTION", "created")
    unless %w[created updated deleted].include?(action)
      abort("ACTION must be one of created|updated|deleted")
    end

    topic, actor = resolve_topic_and_actor(
      ENV["TOPIC_ID"],
      ENV["ACTOR_ID"],
      ENV["RECIPIENT_ID"]
    )

    entry =
      case action
      when "created"
        entry = Entry.create!(
          topic_id: topic.id,
          created_by_id: actor.id,
          updated_by_id: actor.id,
          kind: ENV.fetch("KIND", "expense"),
          currency: "USD",
          amount: ENV.fetch("AMOUNT", "1000").to_i,
          title: ENV.fetch("TITLE") { "Push test #{Time.current.strftime('%H:%M:%S')}" },
          occurred_at: ENV["OCCURRED_AT"] ? Time.zone.parse(ENV["OCCURRED_AT"]) : Time.current
        )
        actor.mark_entry_read!(entry)
        entry
      when "updated"
        entry = topic.entries.order(created_at: :desc).first
        abort("No entries in topic ##{topic.id} - create one first with ACTION=created") if entry.nil?

        entry.update!(
          updated_by_id: actor.id,
          title: ENV.fetch("TITLE") { "#{entry.title} (edited #{Time.current.strftime('%H:%M:%S')})" },
          amount: ENV["AMOUNT"]&.to_i || entry.amount
        )
        actor.mark_entry_read!(entry)
        entry
      when "deleted"
        entry = topic.entries.order(created_at: :desc).first
        abort("No entries in topic ##{topic.id}") if entry.nil?

        entry.soft_delete!
        Entry.unscoped.find(entry.id)
      end

    puts "entry##{entry.id} #{action} by #{actor.nick_name}(#{actor.id}) in topic##{topic.id} \"#{topic.title}\""
    NotifyTopicChange.call(entry: entry, actor: actor, action: action.to_sym)

    print "Waiting for async job"
    3.times { sleep 1; print "." }
    puts "\nDone - check the banner on the simulator/device."
  end

  # Uses TOPIC_ID/ACTOR_ID as-is when given; otherwise finds a topic/actor combo
  # among users with a registered device token that has another follower to act as.
  def resolve_topic_and_actor(topic_id, actor_id, recipient_id)
    if topic_id && actor_id
      return [Topic.unscoped.find(topic_id.to_i), User.find(actor_id.to_i)]
    end

    recipient = if recipient_id
      User.find_by(id: recipient_id.to_i).tap do |user|
        abort("Recipient user##{recipient_id} not found") if user.nil?
        abort("Recipient user##{recipient_id} has no registered device token") unless user.device_tokens.exists?
      end
    else
      DeviceToken.includes(:user).first&.user
    end
    abort("No device tokens registered - enable notifications in the app, or pass TOPIC_ID/ACTOR_ID explicitly") if recipient.nil?

    follows = recipient.topic_follows.where(notifications_enabled: true)
    follows = follows.where(topic_id: topic_id.to_i) if topic_id
    follow = follows.find do |f|
      TopicFollow.where(topic_id: f.topic_id).where.not(user_id: recipient.id).exists?
    end
    abort("Couldn't find a sendable topic/actor combo - check rake push:list and pass TOPIC_ID/ACTOR_ID explicitly") if follow.nil?

    topic = Topic.unscoped.find(topic_id&.to_i || follow.topic_id)
    actor = actor_id ? User.find(actor_id.to_i) : TopicFollow.where(topic_id: topic.id).where.not(user_id: recipient.id).first.user

    puts "(auto-picked) topic=#{topic.id} actor=#{actor.nick_name}(#{actor.id}) -> recipient=#{recipient.nick_name}(#{recipient.id})"
    [topic, actor]
  end
end
