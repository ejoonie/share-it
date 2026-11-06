class EntryMessagesChannel < ApplicationCable::Channel
  def subscribed
    return reject unless params[:entry_id].to_s == chat_entry_id.to_s && accessible?

    stream_from "entry_chat_#{chat_entry_id}", coder: ActiveSupport::JSON do |event|
      if accessible?
        transmit(event) if deliverable?(event)
      else
        transmit({ type: 'access_revoked' })
        stop_all_streams
      end
    end
  end

  private

  def accessible?
    TopicFollow.joins(:user, topic: :entries)
      .where(user_id: current_user.id, users: { token: current_user.token, is_guest: false })
      .where(entries: { id: chat_entry_id })
      .where.not("topic_follows.permissions @> ?::jsonb", '["banned"]')
      .exists?
  end

  def deliverable?(event)
    author_id = event['author_id'] || event[:author_id]
    author_id.blank? || !ChatBlock.between?(current_user.id, author_id)
  end
end
