module Helpers
  module AuthenticationHelper
    def current_user
      token = headers['x-token'] || headers['X-Token']
      error!({ message: 'x-token header is required' }, 401) unless token
      @current_user ||= User.find_by(token: token)
      error!({ message: 'Unauthorized' }, 401) unless @current_user && !@current_user.is_guest?
      @current_user
    end
  end
end
