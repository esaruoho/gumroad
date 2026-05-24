# frozen_string_literal: true

require "test_helper"

class ApplicationMailerTest < ActionMailer::TestCase
  test "includes RescueSmtpErrors" do
    assert ApplicationMailer.include?(RescueSmtpErrors)
  end

  class DeliveryMethodTest < ActionMailer::TestCase
    setup do
      ApplicationMailer.class_eval do
        def test_email
          mail(to: "test@example.com", subject: "Test") do |format|
            format.text { render plain: "Test email content" }
          end
        end
      end
      ActionMailer::Base.delivery_method = :test
      ActionMailer::Base.deliveries.clear
    end

    test "uses MailerInfo.random_delivery_method_options with gumroad domain" do
      mock = Minitest::Mock.new
      mock.expect(:call, {}, [], domain: :gumroad)
      MailerInfo.stub(:random_delivery_method_options, ->(**kwargs) { mock.call(**kwargs) }) do
        ApplicationMailer.new.test_email
      end
      mock.verify
    end

    test "evaluates options lazily and applies them" do
      options = { address: "smtp.sendgrid.net", domain: "gumroad.com" }
      MailerInfo.stub(:random_delivery_method_options, ->(**_) { options }) do
        mail = ApplicationMailer.new.test_email
        options.each { |k, v| assert_equal v, mail.delivery_method.settings[k] }
      end
    end
  end
end
