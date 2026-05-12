module RequestHelpers
  def json_response
    JSON.parse(response.body)
  end

  def post_json(path, params: {}, headers: {}, token: "token_user_one")
    post path,
      params: params.to_json,
      headers: default_json_headers(token).merge(headers)
  end

  def patch_json(path, params: {}, headers: {}, token: "token_user_one")
    patch path,
      params: params.to_json,
      headers: default_json_headers(token).merge(headers)
  end

  def delete_json(path, headers: {}, token: "token_user_one")
    delete path,
      headers: default_json_headers(token).merge(headers)
  end

  def put_json(path, params: {}, headers: {}, token: "token_user_one")
    put path,
      params: params.to_json,
      headers: default_json_headers(token).merge(headers)
  end

  private

  def default_json_headers(token)
    {
      "Content-Type" => "application/json",
      "x-token" => token
    }
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
