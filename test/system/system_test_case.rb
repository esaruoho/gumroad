# frozen_string_literal: true

# Base class for browser tests driven by Playwright.
#
#   class SignupTest < SystemTests::SystemTestCase
#     def test_sign_up_succeeds
#       page.goto(url_for("/signup"))
#       page.fill('input[name="user[email]"]', "buyer@example.com")
#       page.click("button[type=submit]")
#       assert_match(/welcome/i, page.content)
#     end
#   end
#
# Each test gets a fresh Playwright context (clean cookies/storage) and page.
# DB state is reset via DatabaseCleaner truncation because the Puma server
# runs on a separate thread and can't share a transaction with the test.
module SystemTests
  class SystemTestCase < ActiveSupport::TestCase
    self.use_transactional_tests = false

    # Use Rails fixtures (DHH-style) instead of FactoryBot. Loaded once per
    # process; survive DatabaseCleaner truncation because fixture tables are
    # added to the cleaner's `except` list (see boot_dependencies!).
    FIXTURE_PATH = Rails.root.join("test", "fixtures")
    fixtures :all if FIXTURE_PATH.directory? && Dir[FIXTURE_PATH.join("*.yml")].any?

    attr_reader :page, :context

    # `@booted` on the class itself would live on each concrete subclass
    # (FooTest, BarTest), so the body would run once per test class instead
    # of once per process. Track it module-side so it's truly global.
    @boot_dependencies_done = false

    def self.boot_dependencies!
      return if SystemTestCase.instance_variable_get(:@boot_dependencies_done)
      Server.boot
      PlaywrightDriver.boot
      # Disable client-side recaptcha gates so the React forms don't try to
      # load Google's grecaptcha JS (which would hang the page in CI).
      # Server-side `valid_recaptcha_response?` already returns true in
      # Rails.env.test? (see ValidateRecaptcha concern), so this only flips
      # the frontend off. Matches the login pattern that already exists.
      Feature.activate(:disable_login_recaptcha)
      Feature.activate(:disable_signup_recaptcha)
      at_exit do
        Feature.deactivate(:disable_login_recaptcha)
        Feature.deactivate(:disable_signup_recaptcha)
      end
      # Keep fixture tables out of the truncate list so the rows loaded once
      # by `fixtures :all` survive between tests. Schema tables are also
      # preserved (Rails' default).
      fixture_tables = Dir[FIXTURE_PATH.join("*.yml")].map { |f| File.basename(f, ".yml") }
      DatabaseCleaner.strategy = :truncation, {
        except: %w[ar_internal_metadata schema_migrations] + fixture_tables,
      }
      SystemTestCase.instance_variable_set(:@boot_dependencies_done, true)
    end

    def setup
      super
      self.class.boot_dependencies!
      DatabaseCleaner.start
      @context = PlaywrightDriver.new_context
      @context.set_default_timeout(PlaywrightDriver::DEFAULT_TIMEOUT_MS)
      @context.set_default_navigation_timeout(PlaywrightDriver::DEFAULT_NAVIGATION_TIMEOUT_MS)
      @page = @context.new_page
    end

    # Each cleanup step is independent — a Playwright crash closing the page
    # must not skip the DatabaseCleaner reset, otherwise the next test starts
    # with leftover rows. `super` is called last so its failure can't strand
    # the browser context or skip the DB clean either.
    def teardown
      safely { @page&.close }
      safely { @context&.close }
      safely { DatabaseCleaner.clean }
      super
    end

    def url_for(path)
      raise ArgumentError, "path must start with /" unless path.start_with?("/")
      "#{Server.base_url}#{path}"
    end

    private
      def safely
        yield
      rescue StandardError => e
        Rails.logger.warn("[SystemTestCase teardown] #{e.class}: #{e.message}") if defined?(Rails)
      end
  end
end
