# frozen_string_literal: true

require_relative "../test_helper"
require "playwright"
require "database_cleaner/active_record"

require_relative "support/server"
require_relative "support/playwright_driver"
require_relative "system_test_case"
