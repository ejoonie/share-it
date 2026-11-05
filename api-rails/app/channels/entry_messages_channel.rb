class EntryMessagesChannel < ApplicationCable::Channel
  def subscribed
    return reject unless params[:entry_id].to_s == chat_entry_id.to_s && accessible?

    stream_from "entry_chat_#{chat_entry_id}", coder: ActiveSupport::JSON do |event|
      if accessible?
        transmit(event)
      else
        transmit({ type: 'access_revoked' })
        stop_all_streams
      end
    end
  end

  private

  def accessible?
    return false unless User.exists?(id: current_user.id, token: current_user.token, is_guest: false)
    entry = Entry.joins(:topic).find_by(id: chat_entry_id)
    return false unless entry
    follow = TopicFollow.find_by(user_id: current_user.id, topic_id: entry.topic_id)
    follow.present? && !follow.permissions.include?('banned')
  end
end
