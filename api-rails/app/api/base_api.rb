class BaseAPI < Grape::API
  prefix :api
  version :v1, using: :path
  format :json
  default_format :json
  content_type :json, 'application/json'

  helpers ::Helpers::PaginationHelper

  get '/health' do
    status 200

    {
      version: '0.0.0',
      status: 'ok',
      timestamp: Time.now.to_i,
    }
  end
  mount V1::UsersAPI
  mount V1::AuthAPI
  mount V1::TopicsAPI
  namespace :my do
    mount V1::My::BootstrapAPI
    mount V1::My::TopicsAPI
    mount V1::My::EntriesAPI
    mount V1::My::AccountAPI
  end
end
