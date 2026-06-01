# frozen_string_literal: true

class AddEmailIndexesForGdprBuyerErasure < ActiveRecord::Migration[7.1]
  # GdprBuyerErasureService anonymizes guest-buyer PII by querying these tables
  # on their email column. Without an index, the UPDATE on `events`/`signup_events`
  # (very large, write-heavy tables) does a full table scan and locks every row it
  # scans, contending with concurrent inserts until innodb_lock_wait_timeout fires
  # ("Lock wait timeout exceeded"). Indexing the lookup columns turns these into
  # narrow seeks that lock only the matching rows.
  def change
    add_index :events, :email, name: "index_events_on_email"
    add_index :signup_events, :email, name: "index_signup_events_on_email"
    add_index :dispute_evidences, :customer_email, name: "index_dispute_evidences_on_customer_email"
  end
end
