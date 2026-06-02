# frozen_string_literal: true

class Api::V2::ProductSectionsController < Api::V2::BaseController
  PRODUCT_SECTION_TYPE = "products"
  DEFAULT_PRODUCT_SECTION_ATTRIBUTES = {
    default_product_sort: "page_layout",
    shown_products: [],
    show_filters: false,
    add_new_products: false,
  }.freeze

  before_action(only: [:create, :update, :destroy]) { doorkeeper_authorize! :edit_products }
  before_action :fetch_product
  before_action :fetch_section, only: %i[update destroy]

  def create
    return unsupported_section_type(:created) if params[:type] != PRODUCT_SECTION_TYPE

    section_attributes = product_section_attributes(with_defaults: true).merge(
      type: SellerProfileProductsSection.name,
      seller: current_resource_owner
    )

    ActiveRecord::Base.transaction do
      @product.lock!
      @section = @product.seller_profile_sections.create!(section_attributes)
      @product.update!(sections: ordered_section_ids + [@section.id])
    end

    success_with_section(@section)
  rescue InvalidProductSectionParams => e
    render_response(false, message: e.message)
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    render_response(false, message: record_error_message(e))
  end

  def update
    return unsupported_section_type(:updated) unless product_section?
    return unsupported_section_type(:updated) if params.key?(:type) && params[:type] != PRODUCT_SECTION_TYPE

    @section.update!(product_section_attributes(with_defaults: false))

    success_with_section(@section)
  rescue InvalidProductSectionParams => e
    render_response(false, message: e.message)
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    render_response(false, message: record_error_message(e))
  end

  def destroy
    return unsupported_section_type(:deleted) unless product_section?

    ActiveRecord::Base.transaction do
      @product.lock!
      section_ids = ordered_section_ids
      updated_section_ids = section_ids - [@section.id]
      @product.update!(
        sections: updated_section_ids,
        main_section_index: adjusted_main_section_index(section_ids.index(@section.id), updated_section_ids.length)
      )
      @section.destroy!
    end

    success_with_section
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved, ActiveRecord::RecordNotDestroyed => e
    render_response(false, message: record_error_message(e))
  end

  private
    class InvalidProductSectionParams < StandardError; end

    def fetch_section
      @section = @product.seller_profile_sections.find_by_external_id(params[:id])
      error_with_section if @section.nil?
    end

    def product_section_attributes(with_defaults:)
      attributes = with_defaults ? DEFAULT_PRODUCT_SECTION_ATTRIBUTES.dup : {}
      attributes[:header] = params[:header] if params.key?(:header)
      attributes[:hide_header] = boolean_param(:hide_header) if params.key?(:hide_header)
      attributes[:default_product_sort] = params[:default_product_sort] if params.key?(:default_product_sort)
      attributes[:shown_products] = shown_product_ids if params.key?(:shown_products)
      attributes[:show_filters] = boolean_param(:show_filters) if params.key?(:show_filters)
      attributes[:add_new_products] = boolean_param(:add_new_products) if params.key?(:add_new_products)
      attributes
    end

    def shown_product_ids
      shown_products = params[:shown_products]
      raise InvalidProductSectionParams, "shown_products must reference your own product IDs." unless shown_products.is_a?(Array)

      product_ids = shown_products.map do |external_id|
        raise InvalidProductSectionParams, "shown_products must reference your own product IDs." unless external_id.respond_to?(:to_str)

        Link.from_external_id(external_id)
      end

      if product_ids.any?(&:blank?)
        raise InvalidProductSectionParams, "shown_products must reference your own product IDs."
      end

      found_product_ids = current_resource_owner.products.where(id: product_ids.uniq).ids
      if product_ids.uniq.sort != found_product_ids.sort
        raise InvalidProductSectionParams, "shown_products must reference your own product IDs."
      end

      product_ids
    end

    def boolean_param(key)
      case params[key]
      when true, "true", "1", 1
        true
      when false, "false", "0", 0
        false
      else
        raise InvalidProductSectionParams, "#{key} must be true or false."
      end
    end

    def ordered_section_ids
      Array(@product.sections).map(&:to_i)
    end

    def adjusted_main_section_index(deleted_section_index, section_count)
      index = (@product.main_section_index || 0).to_i
      index -= 1 if deleted_section_index && deleted_section_index < index
      [[index, 0].max, section_count].min
    end

    def product_section?
      @section.is_a?(SellerProfileProductsSection)
    end

    def unsupported_section_type(action)
      render_response(false, message: "Only product-listing sections can be #{action} via the API right now.")
    end

    def success_with_section(section = nil)
      success_with_object(:section, section ? Api::ProductSectionsPresenter.new(@product, sections: [section]).props.sole : nil)
    end

    def error_with_section(section = nil)
      error_with_object(:section, section)
    end

    def record_error_message(error)
      error.record.errors.full_messages.presence&.to_sentence || error.message
    end
end
