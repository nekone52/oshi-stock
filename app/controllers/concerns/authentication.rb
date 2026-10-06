# ==========================================
# ログイン・ログアウトの「受付係」のルールブック
# ==========================================
module Authentication
  # このルールをコントローラーでまとめて使えるようにする魔法の合言葉
  extend ActiveSupport::Concern

  # このルールを読み込んだ瞬間に、最初に行う設定
  included do
    # 【基本ルール】画面を開く前に、まず「ログインしてる？」と確認する（部外者は通さない）
    before_action :require_authentication

    # 「ログイン中かどうか」を画面(HTML/ERB)の見た目側でも判定できるように共有する
    helper_method :authenticated?
  end

  # コントローラーごとに例外を作れるルール
  class_methods do
    # 「ログイン画面」や「新規登録」など、誰でも見られないと困る画面だけチェックをパスさせる設定
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

    # 「いまログインしてる？」を YES / NO で答える
    def authenticated?
      resume_session
    end

    # 入場ゲートのチェック処理
    def require_authentication
      # 会員証（Cookie）を持っていれば通過！持っていなければ「ログイン画面へ行ってね」と案内する
      resume_session || request_authentication
    end

    # 手元のメモまたはブラウザの引き出しから会員情報を探す
    def resume_session
      # すでに手元で確認済みならそれを使い、無ければブラウザの引き出し（Cookie）から探す
      Current.session ||= find_session_by_cookie
    end

    # ブラウザの引き出し（Cookie）にある番号をもとに、データベースの棚からデータを取り出す
    def find_session_by_cookie
      # 改ざんされない安全な引き出しに番号があれば、その番号のデータをDBから探す
      Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    # ログインしていなくて弾かれたときの処理
    def request_authentication
      # 「本当はここに行きたかったんだよね」というURLを一時メモ（session）に控えておく
      session[:return_to_after_authenticating] = request.url

      # ログイン画面へ移動させる
      redirect_to new_session_path
    end

    # ログイン成功後、「どこへ案内するか」を決める
    def after_authentication_url
      # 一時メモに「行きたかったURL」が残っていればそれを取り出してそこへ案内。
      # メモが無ければ（最初からログイン画面に来た人など）、トップページへ案内する
      session.delete(:return_to_after_authenticating) || root_url
    end

    # 正しいメアドとパスワードを入れてくれた人に、新しい「会員証」を発行する
    def start_new_session_for(user)
      # どんな端末か(スマホ・PCなど)やIPアドレスを記録して、データベースに新しく保存する
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        # 今動いている処理の中に「この人ログインしたよ！」とセットする
        Current.session = session

        # ブラウザの引き出しに安全な鍵（Cookie）を預ける
        # ・signed: いたずら改ざん防止
        # ・permanent: 有効期限を長くする（閉じてもログインが続く）
        # ・httponly: 悪意あるプログラムから見られないように隠す
        # ・same_site: よその怪しいサイトからの不正操作を防ぐ
        cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
      end
    end

    # ログアウトボタンが押されたときの処理
    def terminate_session
      # データベースに保存してあるセッション情報をゴミ箱へ捨てる
      Current.session.destroy

      # ブラウザの引き出しに預けていた鍵（Cookie）もきれいに消去する
      cookies.delete(:session_id)
    end
end
