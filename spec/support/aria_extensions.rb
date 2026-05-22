# frozen_string_literal: true

Capybara.modify_selector(:button) do
  expression_filter(:role, default: true) do |xpath|
    xpath[XPath.attr(:role).equals("button").or ~XPath.attr(:role)]
  end
end

Capybara.modify_selector(:link) do
  expression_filter(:role, default: true) do |xpath|
    xpath[XPath.attr(:role).equals("link").or ~XPath.attr(:role)]
  end

  expression_filter(:inert, :boolean, default: false) do |xpath, disabled|
    xpath[disabled ? XPath.attr(:"inert") : (~XPath.attr(:"inert"))]
  end
end

# capybara_accessible_selectors does have an implementation for this, but it doesn't use XPath,
# so combining it into :command would be very difficult
Capybara.add_selector(:menuitem, locator_type: [String, Symbol]) do
  xpath do |locator, **options|
    xpath = XPath.descendant[XPath.attr(:role).equals("menuitem")]

    unless locator.nil?
      locator = locator.to_s
      matchers = [XPath.string.n.is(locator),
                  XPath.attr(:title).is(locator),
                  XPath.attr(:'aria-label').is(locator)]
      xpath = xpath[matchers.reduce(:|)]
    end

    xpath
  end

  expression_filter(:disabled, :boolean, default: false) do |xpath, disabled|
    xpath[disabled ? XPath.attr(:"inert") : (~XPath.attr(:"inert"))]
  end
end

Capybara.add_selector(:radio_button, locator_type: [String, Symbol]) do
  xpath do |locator, **options|
    xpath = XPath.descendant[[XPath.self(:input).attr(:type).is("radio"), XPath.attr(:role).one_of("radio", "menuitemradio")].reduce(:|)]
    xpath = locate_field(xpath, locator, **options)
    xpath += XPath.descendant[XPath.attr(:role).one_of("radio", "menuitemradio")][XPath.string.n.is(locator)] if locator
    xpath
  end

  filter_set(:_field, %i[name])

  node_filter(:disabled, :boolean) { |node, value| !(value ^ (node.disabled? || node["inert"] == "true")) }
  node_filter(:checked, :boolean) { |node, value| !(value ^ (node.checked? || node["aria-checked"] == "true")) }
  node_filter(:unchecked, :boolean) { |node, value| (value ^ (node.checked? || node["aria-checked"] == "true")) }

  node_filter(%i[option with]) do |node, value|
    val = node.value
    (value.is_a?(Regexp) ? value.match?(val) : val == value.to_s).tap do |res|
      add_error("Expected value to be #{value.inspect} but it was #{val.inspect}") unless res
    end
  end

  describe_node_filters do |option: nil, with: nil, **|
    desc = +""
    desc << " with value #{option.inspect}" if option
    desc << " with value #{with.inspect}" if with
    desc
  end
end

Capybara.add_selector(:tooltip, locator_type: [nil]) do
  xpath do |locator|
    # TODO: Remove once incorrect locator_type raises an error instead of just logging a warning
    raise "Tooltip does not support a locator, use the `text:` option instead" if locator.present?
    XPath.anywhere[XPath.attr(:role) == "tooltip"]
  end

  node_filter(:attached, default: true) do |node|
    node["id"] == (node.query_scope["aria-describedby"] || node.query_scope.ancestor("[aria-describedby]")["aria-describedby"])
  end
end

Capybara.add_selector(:status, locator_type: [nil]) do
  xpath do |locator|
    # TODO: Remove once incorrect locator_type raises an error instead of just logging a warning
    raise "Status does not support a locator, use the text: option" if locator.present?
    XPath.anywhere[XPath.attr(:role) == "status"]
  end
end

Capybara.modify_selector(:alert) do
  xpath do |*|
    XPath.anywhere[
      (XPath.attr(:role) == "alert") |
      ((XPath.attr(:role) == "status") & XPath.ancestor[XPath.attr(:id) == "flash-toast"])
    ]
  end

  visible do |options|
    :all if options[:text] || options[:exact_text]
  end
end

# Use XPath.anywhere for modals since content may be rendered in a portal
Capybara.modify_selector(:modal) do
  xpath do |*|
    XPath.anywhere[
      [
        XPath.self(:dialog)[XPath.attr(:open)],
        [
          XPath.attr(:"aria-modal") == "true",
          (XPath.attr(:role) == "dialog") | (XPath.attr(:role) == "alertdialog")
        ].reduce(:&)
      ].reduce(&:|)
    ]
  end

  locator_filter do |node, locator, exact:, **|
    next true if locator.nil?

    method = exact ? :eql? : :include?
    labelledby = CapybaraAccessibleSelectors::Helpers.element_labelledby(node) if node[:"aria-labelledby"]
    next true if labelledby&.public_send(method, locator)
    next true if node[:"aria-label"]&.public_send(method, locator.to_s)

    node.has_text?(locator.to_s, exact:, wait: false)
  end
end

Capybara.add_selector(:command) do
  xpath do |locator, **options|
    %i[link button menuitem tab_button].map do |selector|
      expression_for(selector, locator, **options)
    end.reduce(:union)
  end
  node_filter(:disabled, :boolean, default: false, skip_if: :all) { |node, value| !(value ^ node.disabled?) }
  expression_filter(:disabled, :boolean, default: false, skip_if: :all) { |xpath, val| val ? xpath : xpath[~XPath.attr(:"inert")] }
  expression_filter(:role, default: true) do |xpath|
    xpath[XPath.attr(:role).one_of("button", "link", "menuitem", "tab").or ~XPath.attr(:role)]
  end
end

Capybara.add_selector(:combo_box_list_box, locator_type: Capybara::Node::Element) do
  xpath do |input|
    ids = (input[:"aria-owns"] || input[:"aria-controls"])&.split(/\s+/)&.compact

    raise Capybara::ElementNotFound, "listbox cannot be found without attributes aria-owns or aria-controls" if !ids || ids.empty?

    XPath.anywhere[[
      [XPath.attr(:role) == "listbox", XPath.self(:datalist)].reduce(:|),
      ids.map { |id| XPath.attr(:id) == id }.reduce(:|)
    ].reduce(:&)]
  end
end

Capybara.add_selector(:image, locator_type: [String, Symbol]) do
  xpath do |locator, src: nil|
    xpath = XPath.descendant(:img)
    xpath = xpath[XPath.attr(:alt).is(locator)] if locator
    xpath = xpath[XPath.attr(:src).is(src)] if src
    xpath
  end
end

Capybara.add_selector(:tablist, locator_type: [String, Symbol]) do
  xpath do |locator, **options|
    xpath = XPath.descendant[XPath.attr(:role) == "tablist"]
    xpath = xpath[XPath.attr(:"aria-label").is(locator)] if locator
    xpath
  end
end

Capybara.modify_selector(:tab_button) do
  xpath do |name|
    XPath.descendant[[
      XPath.attr(:role) == "tab",
      XPath.ancestor[XPath.attr(:role) == "tablist"],
      XPath.string.n.is(name.to_s) | XPath.attr(:"aria-label").is(name.to_s)
    ].reduce(:&)]
  end
end

Capybara.modify_selector(:table) do
  xpath do |locator|
    xpath = XPath.descendant(:table)
    xpath = xpath[
      XPath.attr(:"aria-label").is(locator) |
      XPath.child(:caption)[XPath.string.n.is(locator)]
    ] if locator
    xpath
  end
end

# support any element with `aria-role` - the default implementation enforces this to be an `input` element
# replace aria-disabled with inert
Capybara.modify_selector(:combo_box) do
  xpath do |locator, allow_self: nil, **options|
    xpath = XPath.axis(allow_self ? :"descendant-or-self" : :descendant)[XPath.attr(:role) == "combobox"]
    locate_field(xpath, locator, **options)
  end

  expression_filter(:expanded, :boolean) do |expr, _value|
    expr
  end

  node_filter(:expanded, :boolean) do |node, value|
    expanded = combo_box_expanded?(node)
    value ? expanded : !expanded
  end

  # with exact enabled options
  node_filter(:enabled_options) do |node, options|
    options = Array(options)
    actual = options_text(node, expression_for(:list_box_option, nil)) { |n| n["inert"] != "true" }
    match_all_options?(actual, options).tap do |res|
      add_error("Expected enabled options #{options.inspect} found #{actual.inspect}") unless res
    end
  end

  # with exact enabled options
  node_filter(:with_enabled_options) do |node, options|
    options = Array(options)
    actual = options_text(node, expression_for(:list_box_option, nil)) { |n| n["inert"] != "true" }
    match_some_options?(actual, options).tap do |res|
      add_error("Expected with at least enabled options #{options.inspect} found #{actual.inspect}") unless res
    end
  end

  # with exact disabled options
  node_filter(:disabled_options) do |node, options|
    options = Array(options)
    actual = options_text(node, expression_for(:list_box_option, nil)) { |n| n["inert"] == "true" }
    match_all_options?(actual, options).tap do |res|
      add_error("Expected disabled options #{options.inspect} found #{actual.inspect}") unless res
    end
  end

  # with exact enabled options
  node_filter(:with_disabled_options) do |node, options|
    options = Array(options)
    actual = options_text(node, expression_for(:list_box_option, nil)) { |n| n["inert"] == "true" }
    match_some_options?(actual, options).tap do |res|
      add_error("Expected with at least disabled options #{options.inspect} found #{actual.inspect}") unless res
    end
  end

  # Override options_text to handle Playwright lazy-rendered listboxes.
  # React combo boxes only populate the listbox DOM on focus/click;
  # Selenium eagerly renders them but Playwright does not.
  def options_text(node, xpath, **opts, &block)
    # First try without expanding (Selenium-compatible fast path)
    begin
      opts[:wait] = false
      listbox = Capybara.page.find(:combo_box_list_box, node, **opts)
      return listbox.all(:xpath, xpath, **opts, &block).map(&:text).map { |t| t.gsub(/[[:space:]]+/, " ").strip }
    rescue Capybara::ElementNotFound
      # Listbox not rendered yet — expand the combo box
    end

    # Click to expand, then read options
    begin
      node.click
      sleep 0.1 # Allow React to render
      opts[:wait] = 2
      listbox = Capybara.page.find(:combo_box_list_box, node, **opts)
      result = listbox.all(:xpath, xpath, wait: false, &block).map(&:text).map { |t| t.gsub(/[[:space:]]+/, " ").strip }
      # Close the listbox
      node.send_keys(:escape) rescue nil
      result
    rescue Capybara::ElementNotFound
      node.send_keys(:escape) rescue nil
      []
    end
  end

  def combo_box_expanded?(node)
    return true if node[:"aria-expanded"] == "true"
    return true if node.matches_selector?("[role='combobox'] [aria-expanded='true']", wait: false)
    return true if node.has_ancestor?("[role='combobox'][aria-expanded='true']", wait: false)

    Capybara.page.find(:combo_box_list_box, node, wait: false).visible?
  rescue Capybara::ElementNotFound
    false
  end
end

Capybara.modify_selector(:list_box_option) do
  expression_filter(:disabled, :boolean) do |expr, value|
    disabled = (XPath.attr(:"aria-disabled") == "true") | XPath.attr(:inert)
    next expr[disabled] if value

    expr[~disabled]
  end
end

# override table_row selector to support colspan
class Capybara::Selector
  # TODO: This appears not to work - see the empty header workaround in ProductsTable and MembershipsTable. We should investigate and fix the XPath.
  def position_considering_colspan(xpath)
    siblings = xpath.preceding_sibling
    siblings[XPath.attr(:colspan).inverse].count.plus(siblings.attr(:colspan).sum).plus(1)
  end
end

Capybara.modify_selector(:table_row) do
  xpath do |locator|
    xpath = XPath.descendant(:tr)
    if locator.is_a? Hash
      locator.reduce(xpath) do |xp, (header, cell)|
        header_xp = XPath.ancestor(:table)[1].descendant(:tr)[1].descendant(:th)[XPath.string.n.is(header)]
        cell_xp = XPath.descendant(:td)[
          XPath.string.n.is(cell) & position_considering_colspan(XPath).equals(position_considering_colspan(header_xp))
        ]
        xp.where(cell_xp)
      end
    elsif locator
      initial_td = XPath.descendant(:td)[XPath.string.n.is(locator.shift)]
      tds = locator.reverse.map { |cell| XPath.following_sibling(:td)[XPath.string.n.is(cell)] }
                   .reduce { |xp, cell| xp.where(cell) }
      xpath[initial_td[tds]]
    else
      xpath
    end
  end
end

Capybara.add_selector(:table_cell) do
  xpath do |header|
    header_xp = XPath.ancestor(:table)[1].descendant(:tr)[1].descendant(:th)[XPath.string.n.is(header)]
    XPath.descendant(:td)[position_considering_colspan(XPath).equals(position_considering_colspan(header_xp))]
  end
end

# add matching by aria-label and handle disabled state
# Use XPath.anywhere for aria-based disclosures since content may be rendered in a portal
Capybara.modify_selector(:disclosure) do
  xpath do |name, **|
    match_name = XPath.string.n.is(name.to_s) | XPath.attr(:"aria-label").equals(name.to_s)
    button = (XPath.self(:button) | (XPath.attr(:role) == "button")) & match_name
    # Standard ARIA pattern: content element exists and is linked via aria-controls
    aria = XPath.anywhere[XPath.attr(:id) == XPath.anywhere[button][XPath.attr(:"aria-expanded")].attr(:"aria-controls")]
    details = XPath.descendant(:details)[XPath.child(:summary)[match_name]]
    aria + details
  end
end

Capybara.modify_selector(:disclosure_button) do
  xpath do |name, **|
    # `XPath.string.n.is(name)` already produces `contains(normalize-space(string(.)), name)`,
    # so an additional `XPath.string.n.contains(name)` clause is redundant and would broaden
    # matching (e.g. searching for "Save" would also match buttons labeled "Save changes").
    match_name = XPath.string.n.is(name.to_s) | XPath.attr(:'aria-label').equals(name.to_s)
    # Require aria-expanded so we only match true disclosure buttons (not arbitrary
    # buttons that happen to carry a matching aria-label).
    disclosure_state = XPath.attr(:'aria-expanded')
    XPath.descendant[[
      (XPath.self(:button) | (XPath.attr(:role) == "button")),
      disclosure_state,
      match_name
    ].reduce(:&)] + XPath.descendant(:summary)[match_name]
  end

  expression_filter(:disabled, :boolean, default: false) do |xpath, val|
    disabled = XPath.attr(:disabled) | XPath.attr(:inert)
    xpath[val ? disabled : ~disabled]
  end

  describe_expression_filters
end

module CapybaraAccessibleSelectors
  module PlaywrightRetryableAccessibilityError
    private
      def _retryable_accessibility_error?(error)
        return true if error.is_a?(Capybara::ElementNotFound) || error.is_a?(Capybara::ExpectationNotMet)
        return true if defined?(Capybara::Playwright::Node::StaleReferenceError) && error.is_a?(Capybara::Playwright::Node::StaleReferenceError)
        return false unless defined?(Playwright::Error) && error.is_a?(Playwright::Error)

        error.message.match?(/Element is not attached to the DOM|Execution context was destroyed|Cannot find context with specified id|Unable to adopt element handle|Target page, context or browser has been closed/)
      end
  end

  module Actions
    include PlaywrightRetryableAccessibilityError

    def select_disclosure(name = nil, **find_options, &block)
      button = _locate_disclosure_button(name, **find_options)
      _toggle_disclosure_button(button, true)

      if block_given?
        _run_in_disclosure(name, **find_options, &block)
      else
        _locate_disclosure(name, **find_options)
      end
    end

    def toggle_disclosure(name = nil, expand: nil, **find_options, &block)
      button = _locate_disclosure_button(name, **find_options)
      _toggle_disclosure_button(button, expand)

      _run_in_disclosure(name, **find_options, &block) if block_given?

      button
    end

    def select_combo_box_option(
      with = nil,
      from: nil,
      currently_with: nil,
      search: with,
      fill_options: {},
      **find_options
    )
      find_options[:with] = currently_with if currently_with
      find_options[:allow_self] = true if from.nil?
      find_option_options = extract_find_option_options(find_options)
      input = find(:combo_box, from, **find_options)

      if search
        begin
          input.set(search, **fill_options)
        rescue Capybara::NotSupportedByDriverError, Playwright::Error
          input.click
        end
      else
        input.click
      end

      listbox = find(:combo_box_list_box, input, **{ wait: find_options[:wait] }.compact)
      option = listbox.find(:list_box_option, with, disabled: false, **find_option_options)
      option = option.find(:css, "td", match: :first) if option.tag_name == "tr"
      option.click
      input
    end

    private
      def _run_in_disclosure(name, **find_options, &block)
        attempts = 0
        begin
          attempts += 1
          disclosure = if is_a?(Capybara::Node::Element) && name.nil?
            _locate_disclosure(name, **find_options)
          else
            # Use page.document to escape any within() scope — portaled content
            # won't be found inside the scoped parent (e.g. a <tr>).
            Capybara.page.document.find(:disclosure, name, **find_options)
          end
          block_executed = false
          wrapped_block = proc { block.call; block_executed = true }
          Capybara.page.within(disclosure, &wrapped_block)
        rescue Capybara::ElementNotFound
          # Radix Popover/DropdownMenu portals don't use aria-controls linking,
          # so the standard :disclosure selector can't find the content element.
          # Fall back to the currently-open popover/menu content rendered in a portal.
          raise if attempts > 1
          popover = Capybara.page.document.find(:css, "[data-radix-popper-content-wrapper] [role='menu'], [data-radix-popper-content-wrapper] [role='listbox'], [data-radix-popper-content-wrapper]", match: :first, wait: 2)
          block_executed = false
          wrapped_block = proc { block.call; block_executed = true }
          begin
            Capybara.page.within(popover, &wrapped_block)
          rescue StandardError => e
            raise unless _retryable_accessibility_error?(e)
            retry if !block_executed && attempts == 1
            raise unless block_executed
          end
        rescue StandardError => e
          raise unless _retryable_accessibility_error?(e)
          retry if !block_executed && attempts == 1
          raise unless block_executed
        end
      end
  end

  module Session
    include PlaywrightRetryableAccessibilityError

    def within_modal(...)
      # Use page.document.find to escape any within() scope — portaled modals
      # won't be found inside the scoped parent (e.g. a <section>).
      modal = Capybara.page.document.find(:modal, ...)
      Capybara.page.within(modal) { yield }
    end

    def within_section(*args, **options, &block)
      attempts = 0
      block_executed = false
      begin
        attempts += 1
        section = find(:section, *args, **options)
        wrapped_block = proc { block.call; block_executed = true }
        within(section, &wrapped_block)
      rescue StandardError => e
        raise unless _retryable_accessibility_error?(e)
        retry if !block_executed && attempts == 1
        # If the block already executed successfully and the error came from
        # within()'s scope-exit cleanup, swallow it — the test work is done.
        # Mirrors _run_in_disclosure's `raise unless block_executed` semantics.
        raise unless block_executed
      end
    end
  end
end

# Re-apply the Session module include so the gem picks up methods (within_section,
# within_modal) added after the gem's own `Capybara::Session.include` ran at load time.
Capybara::Session.include(CapybaraAccessibleSelectors::Session)
Capybara::DSL.include(CapybaraAccessibleSelectors::Session)

module Capybara
  module Node
    module Actions
      def click_command(locator = nil, **options)
        find(:command, locator, **options).click
      end
      alias_method :click_on, :click_command
    end

    class Element
      alias_method :base_hover, :hover

      def hover
        puts "NOTE: Please consider using an interaction method other than .hover to ensure proper accessibility"
        base_hover
      end
    end
  end

  module RSpecMatchers
    %i[tooltip radio_button command image tablist status table_row list_box_option].each do |selector|
      define_method "have_#{selector}" do |locator = nil, **options, &optional_filter_block|
        Matchers::HaveSelector.new(selector, locator, **options, &optional_filter_block)
      end
    end
  end
end

RSpec::Matchers.define :have_table_rows_in_order do |expected_rows|
  match do |actual|
    return false unless expected_rows.is_a?(Array) && expected_rows.any?

    all_table_rows = actual.all(:table_row)
    actual_row_positions = []

    expected_rows.each_with_index do |row_data, index|
      # `#find` fails the assertion if the row is not found, thus we do not
      # need to handle this error in our own `failure_message` implementation.
      found_row = actual.find(:table_row, row_data)

      actual_row_positions << all_table_rows.index(found_row)
    end

    actual_row_positions.each_index do |index|
      next if index == 0

      prev_position = actual_row_positions[index - 1]
      current_position = actual_row_positions[index]

      if current_position < prev_position
        @out_of_order_indices = [index - 1, index]
        return false
      end
    end

    true
  end

  failure_message do |actual|
    first_index, second_index = @out_of_order_indices
    first_row = expected_rows[first_index]
    second_row = expected_rows[second_index]

    <<~TEXT
      expected table rows to be in order, but row
        #{second_row.inspect}
      appeared before row
        #{first_row.inspect}
    TEXT
  end
end
