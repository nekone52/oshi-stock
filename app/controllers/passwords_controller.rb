class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> {
    redirect_to new_password_path, alert: "制限回数を超えました。しばらく時間を置いてから再度お試しください。"
  }

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      PasswordsMailer.reset(user).deliver_later
    end

    redirect_to new_session_path, notice: "パスワード再設定のメールを送りました(登録されているメールアドレスの場合)。"
  end

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: "パスワードを変更しました。新しいパスワードでログインしてください。"
    else
      redirect_to edit_password_path(params[:token]), alert: "パスワードを変更できませんでした。8文字以上で、確認用と同じものを入れてください。"
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: "再設定のリンクが正しくないか、有効期限が切れています。もう一度メールを送ってください。"
    end
end
