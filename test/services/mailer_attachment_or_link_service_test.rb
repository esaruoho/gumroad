# frozen_string_literal: true

require "test_helper"

class MailerAttachmentOrLinkServiceTest < ActiveSupport::TestCase
  setup do
    skip "TODO: migrate spec/services/mailer_attachment_or_link_service_spec.rb " \
         "(uploads to S3 via ExpiringS3FileService — MinIO at localhost:9000 not " \
         "available in Minitest CI lane; trips Makara::Errors::BlacklistedWhileInTransaction)."
  end
end
