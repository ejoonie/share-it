class BaseAPI < Grape::API
  prefix :api
  version :v1, using: :path

  mount V1::TopicsAPI
end
