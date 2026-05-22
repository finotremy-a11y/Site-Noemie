class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("EMAIL_FROM", "nl.cuisinent@gmail.com")
  layout "mailer"
end
