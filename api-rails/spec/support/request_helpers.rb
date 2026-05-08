module RequestHelpers
  def json_response
    JSON.parse(response.body)
  end

  def post_json(path, params: {}, headers: {}, user_id: "user_1")
    post path,
      params: params.to_json,
      headers: default_json_headers(user_id).merge(headers)
  end

  def patch_json(path, params: {}, headers: {}, user_id: "user_1")
    patch path,
      params: params.to_json,
      headers: default_json_headers(user_id).merge(headers)
  end

  def delete_json(path, headers: {}, user_id: "user_1")
    delete path,
      headers: default_json_headers(user_id).merge(headers)
  end

  private

  def default_json_headers(user_id)
    {
      "Content-Type" => "application/json",
      "x-user-id" => user_id
    }
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end

