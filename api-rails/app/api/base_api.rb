class BaseAPI < Grape::API
  prefix :api
  version :v1, using: :path
  format :json
  default_format :json
  content_type :json, 'application/json'

  get '/health' do
    status 200

    {
      version: '0.0.0',
      status: 'ok',
      timestamp: Time.now.to_i,
    }
  end
  mount V1::UsersAPI
  mount V1::TopicsAPI
  namespace :my do
    mount V1::My::TopicsAPI
  end
end
