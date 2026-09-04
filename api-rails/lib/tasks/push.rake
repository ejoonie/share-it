# Dev task for triggering real push notifications against a simulator/device.
# Runs the same flow as the CRUD actions in entries_api.rb (mark_entry_read!,
# soft_delete!, NotifyTopicChange), so notifications sent here match what a
# real app interaction would send.
namespace :push do
  task deeplink: :environment do
    recipient = User.find(50)
    # 이메일로 찾으려면:
    # recipient = User.find_by!(email: "test@example.com")

    raise "수신자에게 등록된 device token이 없습니다" if recipient.device_tokens.none?

    # 수신자 외의 사용자 한 명을 알림 발생자로 선택
    actor = User.where.not(id: recipient.id).first!
    raise "알림 발생자로 사용할 다른 사용자가 없습니다" unless actor

    # actor가 소유한 토픽을 사용하고, 없으면 테스트 토픽 생성
    topic = actor.topics.first || Topic.create!(
      user: actor,
      title: "Push test topic"
    )

    # 수신자가 해당 토픽을 구독하도록 설정
    follow = recipient.follow(topic)
    follow.update!(notifications_enabled: true)
    recipient.update!(notifications_enabled: true)

    # 테스트 엔트리 생성
    entry = Entry.create!(
      topic: topic,
      created_by_id: actor.id,
      updated_by_id: actor.id,
      kind: "expense",
      currency: "USD",
      amount: 1000,
      title: "Push test #{Time.current.strftime("%H:%M:%S")}",
      occurred_at: Time.iso8601("2026-09-03T01:30:00Z")
    )

    actor.mark_entry_read!(entry)

    # 실제 서비스와 같은 경로로 푸시 전송
    NotifyTopicChange.call(
      entry: entry,
      actor: actor,
      action: :created
    )

    puts({
           recipient: "#{recipient.nick_name}(#{recipient.id})",
           actor: "#{actor.nick_name}(#{actor.id})",
           topic_id: topic.id,
           entry_id: entry.id,
           deeplink: PushMessage.for_entry_change(
             entry: entry,
             topic: topic,
             actor: actor,
             action: :created
           ).data[:deeplink]
         })


    ###############################################################
    # edit
    ###############################################################
    entry = Entry.find(54)
    actor = User.find(entry.updated_by_id)

    entry.update!(
      title: "Moved to another date",
      occurred_at: Time.iso8601("2026-09-10T01:30:00Z"),
      updated_by_id: actor.id
    )

    actor.mark_entry_read!(entry)

    message = PushMessage.for_entry_change(
      entry: entry,
      topic: entry.topic,
      actor: actor,
      action: :updated
    )

    puts message.data

    NotifyTopicChange.call(
      entry: entry,
      actor: actor,
      action: :updated
    )


    ###############################################################
    # delete
    ###############################################################
    entry = Entry.find(185)
    actor = User.find(entry.updated_by_id)

    # 삭제 전에 날짜를 보존
    occurred_at = entry.occurred_at

    entry.soft_delete!
    entry = Entry.unscoped.find(entry.id)

    message = PushMessage.for_entry_change(
      entry: entry,
      topic: entry.topic,
      actor: actor,
      action: :deleted
    )

    puts({
           entry_id: entry.id,
           occurred_at: occurred_at,
           deeplink: message.data[:deeplink]
         })

    NotifyTopicChange.call(
      entry: entry,
      actor: actor,
      action: :deleted
    )


    #################################################################
    # unauthorized or deleted
    #################################################################
    actor = User.find(54)
    recipient = User.find(53)

    raise "user#53에 디바이스 토큰이 없습니다" if recipient.device_tokens.none?

    recipient.update!(notifications_enabled: true)

    # 54가 소유한 새 테스트 토픽
    topic = Topic.create!(
      user: actor,
      title: "Deleted entry access test"
    )

    # 53이 알림을 받을 수 있도록 구독
    recipient.follow(topic).update!(notifications_enabled: true)

    # 54가 엔트리 생성
    entry = Entry.create!(
      topic: topic,
      created_by_id: actor.id,
      updated_by_id: actor.id,
      kind: "expense",
      currency: "USD",
      amount: 1000,
      title: "Delete before user 53 opens",
      occurred_at: Time.current
    )

    actor.mark_entry_read!(entry)

    # 생성 알림 전송
    NotifyTopicChange.call(
      entry: entry,
      actor: actor,
      action: :created
    )

    puts({
           actor_id: actor.id,
           recipient_id: recipient.id,
           topic_id: topic.id,
           entry_id: entry.id,
           deeplink: PushMessage.for_entry_change(
             entry: entry,
             topic: topic,
             actor: actor,
             action: :created
           ).data[:deeplink]
         })


    ###
    entry.soft_delete!
    entry.reload.deleted_at
  end


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
