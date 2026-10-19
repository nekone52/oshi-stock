class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> {
    redirect_to new_session_path, alert: "制限回数を超えました。しばらく時間を置いてから再度お試しください。"
  }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to after_authentication_url, notice: "ログインしました。"
    else
      redirect_to new_session_path, alert: "メールアドレスかパスワードがちがいます。"
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other, notice: "ログアウトしました。"
  end
end
