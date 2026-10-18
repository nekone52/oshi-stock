class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@send.oshi-stock.com"
  layout "mailer"
end
