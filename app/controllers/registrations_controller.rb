class RegistrationsController < ApplicationController
  # 【未ログインOK】新規登録画面の表示（new）と登録（create）はログイン前でもアクセス許可
  allow_unauthenticated_access only: %i[new create]

  # 【連打・攻撃防止】3分間に10回以上の登録試行をブロック
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> {
    redirect_to new_registration_url, alert: "制限回数を超えました。しばらく時間を置いてから再度お試しください。"
  }

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      # 保存できたら自動ログインしてトップ画面へ案内
      start_new_session_for @user
      redirect_to root_path, notice: "アカウントを登録しました。"
    else
      # 422エラーの合図を添えて登録画面を再描画（Turboがエラー表示を出すために必須）
      render :new, status: :unprocessable_content
    end
  end

  private

  # 【荷物検査】
  # メールアドレス、パスワード、確認用パスワード（一致チェック用）の3つだけを通す
  def user_params
    params.expect(user: [ :email_address, :password, :password_confirmation ])
  end
end
