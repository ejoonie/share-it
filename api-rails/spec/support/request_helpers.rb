module RequestHelpers
  def json_response
    JSON.parse(response.body)
  end

  def get_json(path, login_user: nil, headers: {})
    get path,
      headers: default_json_headers(login_user&.token).merge(headers)
  end

  def post_json(path, login_user: nil, params: {}, headers: {})
    post path,
      params: params.to_json,
      headers: default_json_headers(login_user&.token).merge(headers)
  end

  def patch_json(path, login_user: nil, params: {}, headers: {})
    patch path,
      params: params.to_json,
      headers: default_json_headers(login_user&.token).merge(headers)
  end

  def delete_json(path, login_user: nil, headers: {})
    delete path,
      headers: default_json_headers(login_user&.token).merge(headers)
  end

  def put_json(path, login_user: nil, params: {}, headers: {})
    put path,
      params: params.to_json,
      headers: default_json_headers(login_user&.token).merge(headers)
  end

  private

  def default_json_headers(token)
    headers = {
      "Content-Type" => "application/json",
    }
    headers["x-token"] = token if token
    headers
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
