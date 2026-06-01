# frozen_string_literal: true

require "spec_helper"

# GdprBuyerErasureService anonymizes guest-buyer PII with `update_all` queries
# keyed on the email column of each table. On the large, write-heavy `events`
# and `signup_events` tables, a missing index forced a full-table scan that
# locked every scanned row and contended with concurrent inserts until
# innodb_lock_wait_timeout fired ("Lock wait timeout exceeded"). These indexes
# keep the erasure a narrow seek. See issue #438.
describe "GDPR buyer erasure lookup indexes" do
  let(:connection) { ActiveRecord::Base.connection }

  {
    events: :email,
    signup_events: :email,
    dispute_evidences: :customer_email,
  }.each do |table, column|
    it "has an index on #{table}.#{column} so erasure does not full-scan the table" do
      expect(connection.index_exists?(table, column)).to be(true)
    end
  end
end
