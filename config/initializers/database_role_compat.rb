# frozen_string_literal: true

# Drop-in replacement for Makara's `stick_to_primary!` and `Makara::Context.release_all`.
# Provides the same API so call sites need minimal changes.
#
# Usage:
#   ActiveRecord::Base.connection.stick_to_primary!
#     → Now a no-op. The Rails DatabaseSelector middleware handles automatic
#       read/write splitting for web requests. Sidekiq jobs already default to
#       the writing role. For explicit primary reads, wrap code in:
#       ActiveRecord::Base.connected_to(role: :writing) { ... }
#
module DatabaseRoleCompat
  # Backwards-compatible no-op. Makara's stick_to_primary! pinned the current
  # thread to the primary for the rest of the request. With Rails native multi-DB,
  # the DatabaseSelector middleware handles this automatically (2-second delay after
  # writes). Sidekiq jobs already use the writing role by default.
  #
  # Call sites that used stick_to_primary! fall into two categories:
  # 1. Web controllers after checkout: the DatabaseSelector middleware already routes
  #    POST responses and subsequent GETs (within the delay window) to primary.
  # 2. Sidekiq jobs: always run on primary (no middleware), so this is already a no-op.
  # 3. Critical reads needing latest data: these should use
  #    ActiveRecord::Base.connected_to(role: :writing) { ... } explicitly.
  def stick_to_primary!
    # No-op: Rails native multi-DB handles this via DatabaseSelector middleware
    # and Sidekiq jobs always use the writing role.
  end
end

# Route a block to the reading role (replica) when available, falling back to
# the writing role (primary) when no replica is configured (e.g., test/dev).
# Replaces Makara::Context.release_all + query patterns.
module DatabaseRoleHelper
  def self.read_from_replica(&block)
    if ENV["USE_DB_WORKER_REPLICAS"] == "true"
      ActiveRecord::Base.connected_to(role: :reading, &block)
    else
      yield
    end
  end
end

# Patch the adapter to respond to stick_to_primary! for backwards compatibility
ActiveSupport.on_load(:active_record) do
  ActiveRecord::ConnectionAdapters::AbstractAdapter.include(DatabaseRoleCompat)
end
