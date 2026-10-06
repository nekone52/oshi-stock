# リクエストのテストで、ログインした状態にするための手助け
module LoginHelpers
  def sign_in_as(user, password: "password")
    post session_path, params: { email_address: user.email_address, password: password }
  end
end

RSpec.configure do |config|
  config.include LoginHelpers, type: :request
end
