require "test_helper"

class ConsumptionEventTest < ActiveSupport::TestCase
  setup do
    @url_redirect = url_redirects(:pdf_stamping_url_redirect)
    @purchase = @url_redirect.purchase
    @product = @purchase.link
    @product_file = product_files(:pdf_stamping_file_one)
  end

  def required_params
    {
      event_type: ConsumptionEvent::EVENT_TYPE_DOWNLOAD,
      platform: Platform::WEB,
      url_redirect_id: @url_redirect.id,
      ip_address: "0.0.0.0",
    }
  end

  test ".create_event! creates an event with required parameters" do
    assert_difference -> { ConsumptionEvent.count }, 1 do
      ConsumptionEvent.create_event!(**required_params)
    end
    event = ConsumptionEvent.last
    assert_equal ConsumptionEvent::EVENT_TYPE_DOWNLOAD, event.event_type
    assert_equal Platform::WEB, event.platform
    assert_equal @url_redirect.id, event.url_redirect_id
    assert_equal "0.0.0.0", event.ip_address
  end

  test ".create_event! raises an error if a required parameter is missing" do
    required_params.each_key do |key|
      assert_raises(KeyError) { ConsumptionEvent.create_event!(**required_params.except(key)) }
    end
  end

  test ".create_event! assigns default values to optional parameters when not provided" do
    event = ConsumptionEvent.create_event!(**required_params)
    assert_nil event.product_file_id
    assert_nil event.purchase_id
    assert_nil event.link_id
    assert_nil event.folder_id
    assert_in_delta Time.current.to_f, event.consumed_at.to_f, 60
  end

  test ".create_event! uses provided values for optional parameters when available" do
    folder = ProductFolder.create!(link: @product, name: "Folder One")
    other_params = {
      product_file_id: @product_file.id,
      purchase_id: @purchase.id,
      product_id: @product.id,
      folder_id: folder.id,
      consumed_at: 2.days.ago,
    }
    event = ConsumptionEvent.create_event!(**required_params.merge(other_params))
    assert_equal @product_file.id, event.product_file_id
    assert_equal @purchase.id, event.purchase_id
    assert_equal @product.id, event.link_id
    assert_equal folder.id, event.folder_id
    assert_in_delta 2.days.ago.to_f, event.consumed_at.to_f, 60
  end

  test "raises error if event_type is invalid" do
    event = ConsumptionEvent.new(
      product_file_id: @product_file.id,
      url_redirect_id: @url_redirect.id,
      purchase_id: @purchase.id,
      platform: "web",
      consumed_at: "2015-09-09T17:26:50PDT",
    )
    event.event_type = "invalid_event"
    event.validate
    assert_includes event.errors.full_messages, "Event type is not included in the list"
  end

  test "raises error if platform is invalid" do
    event = ConsumptionEvent.new(
      product_file_id: @product_file.id,
      url_redirect_id: @url_redirect.id,
      purchase_id: @purchase.id,
      platform: "invalid_platform",
      consumed_at: "2015-09-09T17:26:50PDT",
    )
    event.event_type = "read"
    event.validate
    assert_includes event.errors.full_messages, "Platform is not included in the list"
  end
end
