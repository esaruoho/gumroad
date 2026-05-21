# frozen_string_literal: true

# Previously patched Selenium's Bridge to re-raise Chrome's UnknownError as
# StaleElementReferenceError. Playwright handles stale elements natively via
# its auto-retry mechanism, so this patch is no longer needed.
#
# Kept as an empty file to avoid LoadError if referenced elsewhere.
