# アプリが起きるときに、Resend(メール送信)に APIキーをわたす
# キーはコードに直接書かない。金庫(credentials)の resend: → api_key: から取り出す
# 【自分の言葉】金庫から Resend の通行証を出して、Resend にわたす
Resend.api_key = Rails.application.credentials.dig(:resend, :api_key)
