module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user, :chat_entry_id

    def connect
      payload = Rails.application.message_verifier(:chat_connection).verified(
        request.params[:ticket], purpose: :chat_connection
      )
      reject_unauthorized_connection unless payload
      payload = payload.with_indifferent_access
      self.current_user = User.find_by(id: payload[:user_id], is_guest: false)
      reject_unauthorized_connection unless current_user &&
        ActiveSupport::SecurityUtils.secure_compare(
          Digest::SHA256.hexdigest(current_user.token), payload[:token_digest]
        )
      self.chat_entry_id = payload[:entry_id]
    end

    protected

    # Native clients send no Origin and authenticate with a short-lived ticket.
    # Browser requests retain Rails' normal same-origin validation.
    def allow_request_origin?
      request.origin.nil? || super
    end
  end
end
