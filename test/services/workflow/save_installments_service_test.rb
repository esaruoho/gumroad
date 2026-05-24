# frozen_string_literal: true

require "test_helper"

class Workflow::SaveInstallmentsServiceTest < ActiveSupport::TestCase
  setup do
    @seller = users(:named_seller)
    @seller.update_columns(confirmed_at: Time.current)
    @product = Link.bypass_product_creation_limit do
      Link.create!(user: @seller, name: "Workflow installments product", price_cents: 100)
    end
    @workflow = Workflow.create!(seller: @seller, link: @product, workflow_type: Workflow::PRODUCT_TYPE, name: "Workflow")
  end

  test "returns an error when installments data is missing" do
    success, errors = process(params: base_params.except(:installments))

    assert_equal false, success
    assert_equal "Installments data is required", errors.full_messages.first
  end

  test "abandoned cart workflow requires exactly one installment" do
    workflow = Workflow.create!(seller: @seller, workflow_type: Workflow::ABANDONED_CART_TYPE, name: "Abandoned")

    [[], [default_installment_params, default_installment_params]].each do |installments|
      success, errors = process(workflow:, params: base_params.merge(installments:))

      assert_equal false, success
      assert_equal "An abandoned cart workflow can only have one email.", errors.full_messages.first
      assert_empty workflow.installments.alive
    end
  end

  test "abandoned cart workflow appends product placeholder when missing" do
    workflow = Workflow.create!(seller: @seller, workflow_type: Workflow::ABANDONED_CART_TYPE, name: "Abandoned")

    assert_difference -> { workflow.installments.alive.count }, 1 do
      success, errors = process(workflow:, params: base_params.merge(installments: [default_installment_params]))
      assert_equal true, success
      assert_nil errors
    end

    assert_equal "Lorem ipsum<product-list-placeholder></product-list-placeholder>", workflow.installments.alive.last.message
  end

  test "creates an installment with inherited workflow fields and rule" do
    assert_difference -> { @workflow.installments.alive.count }, 1 do
      success, errors = process
      assert_equal true, success
      assert_nil errors
    end

    installment = @workflow.installments.alive.last
    assert_equal "An email", installment.name
    assert_equal "Lorem ipsum", installment.message
    assert installment.send_emails?
    assert_equal @workflow.workflow_type, installment.installment_type
    assert_equal @workflow.json_data, installment.json_data
    assert_equal @workflow.seller_id, installment.seller_id
    assert_equal @workflow.link_id, installment.link_id
    assert_equal @workflow.base_variant_id, installment.base_variant_id
    assert_equal !@workflow.send_to_past_customers?, installment.is_for_new_customers_of_workflow?
    assert_nil installment.published_at
    assert_not installment.workflow_installment_published_once_already?
    assert_equal 1.hour.to_i, installment.installment_rule.delayed_delivery_time
    assert_equal InstallmentRule::HOUR, installment.installment_rule.time_period
  end

  test "updates an existing installment and rule and records id mapping" do
    installment = create_installment(name: "Installment 1", message: "Message 1")
    installment.create_installment_rule!(delayed_delivery_time: 1.hour.to_i, time_period: InstallmentRule::HOUR)

    params = base_params.merge(
      installments: [
        default_installment_params.merge(
          id: installment.external_id,
          name: "Installment 1 (edited)",
          message: "Updated message",
          time_duration: 2,
          time_period: InstallmentRule::DAY
        )
      ]
    )
    service = service_for(params:)

    assert_no_difference -> { @workflow.installments.alive.count } do
      success, errors = nil
      SaveFilesService.stub(:perform, true) do
        success, errors = service.process
      end
      assert_equal true, success
      assert_nil errors
    end

    assert_equal "Installment 1 (edited)", installment.reload.name
    assert_equal "Updated message", installment.message
    assert_equal 2.days.to_i, installment.installment_rule.delayed_delivery_time
    assert_equal InstallmentRule::DAY, installment.installment_rule.time_period
    assert_equal({ installment.external_id => installment.external_id }, service.old_and_new_installment_id_mapping)
  end

  test "deletes installments missing from params and deletes their rules" do
    removed = create_installment
    removed_rule = removed.create_installment_rule!(delayed_delivery_time: 1.hour.to_i, time_period: InstallmentRule::HOUR)

    assert_difference -> { @workflow.installments.alive.count }, -1 do
      success, errors = process(params: base_params.merge(installments: []))
      assert_equal true, success
      assert_nil errors
    end

    assert_predicate removed.reload.deleted_at, :present?
    assert_predicate removed_rule.reload.deleted_at, :present?
  end

  test "reschedules a published installment when delay changes on save" do
    published_at = 1.hour.ago
    @workflow.update_columns(published_at:, first_published_at: published_at)
    installment = create_installment(published_at:)
    installment.create_installment_rule!(delayed_delivery_time: 1.hour.to_i, time_period: InstallmentRule::HOUR)
    schedule_calls = []

    with_schedule_installment_stub(schedule_calls) do
      success, errors = process(
        params: base_params.merge(
          installments: [
            default_installment_params.merge(id: installment.external_id, time_duration: 2, time_period: InstallmentRule::DAY)
          ]
        )
      )

      assert_equal true, success
      assert_nil errors
    end

    assert_equal [[@workflow.id, installment.id, 1.hour.to_i]], schedule_calls
    assert_equal 2.days.to_i, installment.reload.installment_rule.delayed_delivery_time
  end

  test "does not reschedule when delay is unchanged" do
    published_at = 1.hour.ago
    @workflow.update_columns(published_at:, first_published_at: published_at)
    installment = create_installment(published_at:)
    installment.create_installment_rule!(delayed_delivery_time: 1.hour.to_i, time_period: InstallmentRule::HOUR)
    schedule_calls = []

    with_schedule_installment_stub(schedule_calls) do
      success, errors = process(params: base_params.merge(installments: [default_installment_params.merge(id: installment.external_id)]))

      assert_equal true, success
      assert_nil errors
    end
    assert_empty schedule_calls
  end

  test "updates send_to_past_customers only before first publish" do
    success, = process(params: base_params.merge(send_to_past_customers: true))
    assert_equal true, success
    assert @workflow.reload.send_to_past_customers?

    @workflow.update_columns(first_published_at: 1.hour.ago)
    success, = process(params: base_params.merge(send_to_past_customers: false))
    assert_equal true, success
    assert @workflow.reload.send_to_past_customers?
  end

  test "does not save invalid installments" do
    assert_no_difference -> { @workflow.installments.alive.count } do
      success, errors = process(params: base_params.merge(installments: [default_installment_params.merge(message: "")]))

      assert_equal false, success
      assert_equal "Please include a message as part of the update.", errors.full_messages.first
    end
  end

  test "sends preview email when requested" do
    installment = create_installment
    installment.create_installment_rule!(delayed_delivery_time: 1.hour.to_i, time_period: InstallmentRule::HOUR)
    preview_email_calls = []

    with_send_preview_email_stub(preview_email_calls) do
      success, errors = process(
        params: base_params.merge(
          installments: [default_installment_params.merge(id: installment.external_id, name: "Previewed", send_preview_email: true)]
        )
      )

      assert_equal true, success
      assert_nil errors
    end

    assert_equal [[installment.id, @seller.id]], preview_email_calls
    assert_equal "Previewed", installment.reload.name
  end

  private
    def process(workflow: @workflow, params: base_params)
      SaveFilesService.stub(:perform, true) do
        service_for(workflow:, params:).process
      end
    end

    def service_for(workflow: @workflow, params: base_params)
      Workflow::SaveInstallmentsService.new(
        seller: @seller,
        params:,
        workflow:,
        preview_email_recipient: @seller
      )
    end

    def base_params
      {
        save_action_name: Workflow::SAVE_ACTION,
        send_to_past_customers: false,
        installments: [default_installment_params]
      }
    end

    def default_installment_params
      {
        id: SecureRandom.uuid,
        name: "An email",
        message: "Lorem ipsum",
        time_duration: 1,
        time_period: InstallmentRule::HOUR,
        send_preview_email: false,
        files: []
      }
    end

    def create_installment(attributes = {})
      Installment.create!(
        {
          seller: @seller,
          link: @product,
          workflow: @workflow,
          name: "Installment",
          message: "Message",
          installment_type: @workflow.workflow_type,
          send_emails: true
        }.merge(attributes)
      )
    end

    def with_schedule_installment_stub(calls)
      original_method = Workflow.instance_method(:schedule_installment)
      Workflow.define_method(:schedule_installment) do |installment, old_delayed_delivery_time: nil|
        calls << [id, installment.id, old_delayed_delivery_time]
      end

      yield
    ensure
      Workflow.remove_method(:schedule_installment)
      Workflow.define_method(:schedule_installment, original_method)
    end

    def with_send_preview_email_stub(calls)
      original_method = Installment.instance_method(:send_preview_email)
      Installment.define_method(:send_preview_email) do |recipient_user|
        calls << [id, recipient_user.id]
      end

      yield
    ensure
      Installment.remove_method(:send_preview_email)
      Installment.define_method(:send_preview_email, original_method)
    end
end
