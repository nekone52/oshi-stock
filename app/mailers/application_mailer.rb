class ApplicationMailer < ActionMailer::Base
  # 送り主は、Resend で確認ずみの部屋(send.oshi-stock.com)の no-reply(返信しないでね)。個人のアドレスは使わない
  default from: "no-reply@send.oshi-stock.com"
  layout "mailer"
end
