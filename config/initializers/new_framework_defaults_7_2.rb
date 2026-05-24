# frozen_string_literal: true

# Be sure to restart your server when you modify this file.
#
# This file eases your Rails 7.2 framework defaults upgrade.
#
# `config.load_defaults 7.2` is already set in config/application.rb.
# This file PRESERVES legacy behavior for:
#   (a) Rails 7.1 defaults that were deferred in the previous upgrade pass
#       and have not yet been adopted, and
#   (b) Rails 7.2 defaults that carry rollout risk for this app.
#
# Each preserved default should be re-evaluated and removed (unpinned)
# in a follow-up PR once we've verified it's safe.

# ---------------------------------------------------------------------------
# Rails 7.1 defaults deferred from the previous upgrade
# ---------------------------------------------------------------------------

# NOTE: `add_autoload_paths_to_load_path = true` is set in config/application.rb,
# not here — it must be applied before initializers run.

# Continue running `after_commit` callbacks on the FIRST of multiple AR
# instances saved within a transaction (legacy behavior). Some app code
# relies on which instance receives the callback; flip in a follow-up.
Rails.application.config.active_record.run_commit_callbacks_on_first_saved_instances_in_transaction = true

# Keep the legacy Query Logs tag format. `:sqlcommenter` changes the format
# of every SQL comment, which downstream log scrapers may not parse.
Rails.application.config.active_record.query_log_tags_format = :legacy

# Continue validating the full parent record (extra query) when a `belongs_to`
# is mandatory. The new behavior validates only the foreign key column, which
# is faster but can mask referential integrity gaps; flip in a follow-up.
Rails.application.config.active_record.belongs_to_required_validates_foreign_key = true

# Keep `after_commit` and `after_*_commit` callbacks running in the LEGACY
# (inverse-definition) order. The new order matches other callbacks but
# can subtly change ordering-sensitive side effects.
Rails.application.config.active_record.run_after_transaction_callbacks_in_order_defined = false

# Continue silently committing a `transaction` block when exited via
# `return`/`break`/`throw`. The new behavior rolls back, which can change
# semantics for code that intentionally exits a transaction early.
Rails.application.config.active_record.commit_transaction_on_non_local_return = false

# Continue using the HTML4 sanitizer vendor in Action View. The new HTML5
# sanitizer can subtly alter rendered output; flip in a follow-up after a
# visual diff sweep.
Rails.application.config.action_view.sanitizer_vendor = Rails::HTML4::Sanitizer

# ---------------------------------------------------------------------------
# Rails 7.2 defaults pinned for safety
# ---------------------------------------------------------------------------

# Rails 7.2 sets `Regexp.timeout = 1.second` globally. Any regex anywhere in
# the app (gems included) that takes >1s now raises `Regexp::TimeoutError`.
# Audit and tune regex hotspots first, then remove this pin in a follow-up.
Regexp.timeout = nil

# Rails 7.2 enables `validate_migration_timestamps = true`, which rejects
# migrations whose timestamp is more than 1 day in the future. This repo
# uses intentionally future-dated migration timestamps (a convention to
# avoid timestamp collisions across concurrent PRs), so disable the check.
Rails.application.config.active_record.validate_migration_timestamps = false
