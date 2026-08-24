module AuthenticationHelpers
  # Cabecera lista para un request autenticado como `user`.
  def auth_headers_for(user)
    { "Authorization" => "Bearer #{user.sessions.create!.token}" }
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
end
