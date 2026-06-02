# frozen_string_literal: true

require "spec_helper"
require "shared_examples/authorized_oauth_v1_api_method"

describe Api::V2::ProductSectionsController do
  before do
    @user = create(:user)
    @app = create(:oauth_application, owner: create(:user))
    @product = create(:product, user: @user)
  end

  describe "POST 'create'" do
    before do
      @action = :create
      @shown_product1 = create(:product, user: @user)
      @shown_product2 = create(:product, user: @user)
      @params = {
        link_id: @product.external_id,
        type: "products",
        header: "Featured picks",
        hide_header: false,
        shown_products: [@shown_product2.external_id, @shown_product1.external_id],
        default_product_sort: "highest_rated",
        show_filters: true,
        add_new_products: false,
      }
    end

    it_behaves_like "authorized oauth v1 api method"
    it_behaves_like "authorized oauth v1 api method only for edit_products scope"

    describe "when logged in with edit_products scope" do
      before do
        @token = create("doorkeeper/access_token", application: @app, resource_owner_id: @user.id, scopes: "edit_products")
        @params.merge!(access_token: @token.token)
      end

      it "creates a product section, appends it to the product order, and returns the serialized section" do
        expect do
          post @action, params: @params
        end.to change { @product.seller_profile_sections.count }.by(1)

        section = @product.seller_profile_sections.sole
        expect(section).to be_a(SellerProfileProductsSection)
        expect(section.seller).to eq(@user)
        expect(@product.reload.sections).to eq([section.id])
        expect(response.parsed_body["section"]).to eq(
          {
            "id" => section.external_id,
            "type" => "products",
            "header" => "Featured picks",
            "hide_header" => false,
            "shown_products" => [@shown_product2.external_id, @shown_product1.external_id],
            "default_product_sort" => "highest_rated",
            "show_filters" => true,
            "add_new_products" => false,
          }
        )
        expect(@product.as_json(api_scopes: ["edit_products"])["sections"].sole).to eq(response.parsed_body["section"])
      end

      it "applies product section defaults when fields are omitted" do
        post @action, params: { link_id: @product.external_id, type: "products", access_token: @token.token }

        section = @product.seller_profile_sections.sole
        expect(response.parsed_body["section"]).to eq(
          {
            "id" => section.external_id,
            "type" => "products",
            "header" => "",
            "hide_header" => false,
            "shown_products" => [],
            "default_product_sort" => "page_layout",
            "show_filters" => false,
            "add_new_products" => false,
          }
        )
      end

      it "rejects shown_products that are not the seller's products" do
        foreign_product = create(:product)

        post @action, params: @params.merge(shown_products: [foreign_product.external_id])

        expect(response.parsed_body).to eq(
          {
            "success" => false,
            "message" => "shown_products must reference your own product IDs.",
          }
        )
        expect(@product.reload.seller_profile_sections).to be_empty
        expect(@product.sections).to eq([])
      end

      it "rejects unknown shown_products" do
        post @action, params: @params.merge(shown_products: [ObfuscateIds.encrypt(999_999_999)])

        expect(response.parsed_body).to eq(
          {
            "success" => false,
            "message" => "shown_products must reference your own product IDs.",
          }
        )
      end

      it "rejects unsupported section types" do
        post @action, params: @params.merge(type: "rich_text")

        expect(response.parsed_body).to eq(
          {
            "success" => false,
            "message" => "Only product-listing sections can be created via the API right now.",
          }
        )
        expect(@product.reload.seller_profile_sections).to be_empty
      end
    end
  end

  describe "PUT 'update'" do
    before do
      @old_product = create(:product, user: @user)
      @new_product = create(:product, user: @user)
      @section = create(:seller_profile_products_section, seller: @user, product: @product, shown_products: [@old_product.id])
      @other_section = create(:seller_profile_rich_text_section, seller: @user, product: @product)
      @product.update!(sections: [@other_section.id, @section.id])
      @action = :update
      @params = {
        link_id: @product.external_id,
        id: @section.external_id,
        header: "Updated picks",
        hide_header: true,
        shown_products: [@new_product.external_id],
        default_product_sort: "price_asc",
        show_filters: true,
        add_new_products: false,
      }
    end

    it_behaves_like "authorized oauth v1 api method"
    it_behaves_like "authorized oauth v1 api method only for edit_products scope"

    describe "when logged in with edit_products scope" do
      before do
        @token = create("doorkeeper/access_token", application: @app, resource_owner_id: @user.id, scopes: "edit_products")
        @params.merge!(access_token: @token.token)
      end

      it "updates product section fields without changing product section order" do
        put @action, params: @params

        expect(@product.reload.sections).to eq([@other_section.id, @section.id])
        expect(@section.reload).to have_attributes(
          header: "Updated picks",
          shown_products: [@new_product.id],
          default_product_sort: "price_asc",
          show_filters: true,
          add_new_products: false
        )
        expect(@section.hide_header?).to be(true)
        expect(response.parsed_body["section"]).to include(
          "id" => @section.external_id,
          "type" => "products",
          "header" => "Updated picks",
          "hide_header" => true,
          "shown_products" => [@new_product.external_id],
          "default_product_sort" => "price_asc",
          "show_filters" => true,
          "add_new_products" => false
        )
      end

      it "rejects unsupported section type changes" do
        put @action, params: @params.merge(type: "rich_text")

        expect(response.parsed_body).to eq(
          {
            "success" => false,
            "message" => "Only product-listing sections can be updated via the API right now.",
          }
        )
        expect(@section.reload.header).to be_nil
      end

      it "does not update sections from another product" do
        other_product = create(:product, user: @user)
        other_section = create(:seller_profile_products_section, seller: @user, product: other_product)

        put @action, params: @params.merge(id: other_section.external_id)

        expect(response.parsed_body).to eq(
          {
            "success" => false,
            "message" => "The section was not found.",
          }
        )
        expect(other_section.reload.header).to be_nil
      end
    end
  end

  describe "DELETE 'destroy'" do
    before do
      @section = create(:seller_profile_products_section, seller: @user, product: @product)
      @other_section = create(:seller_profile_rich_text_section, seller: @user, product: @product)
      @product.update!(sections: [@other_section.id, @section.id])
      @action = :destroy
      @params = {
        link_id: @product.external_id,
        id: @section.external_id,
      }
    end

    it_behaves_like "authorized oauth v1 api method"
    it_behaves_like "authorized oauth v1 api method only for edit_products scope"

    describe "when logged in with edit_products scope" do
      before do
        @token = create("doorkeeper/access_token", application: @app, resource_owner_id: @user.id, scopes: "edit_products")
        @params.merge!(access_token: @token.token)
      end

      it "removes the section from product order and destroys the section" do
        delete @action, params: @params

        expect(response.parsed_body).to eq(
          {
            "success" => true,
            "message" => "The section was deleted successfully.",
          }
        )
        expect(@product.reload.sections).to eq([@other_section.id])
        expect(SellerProfileSection.exists?(@section.id)).to be(false)
      end

      it "moves main_section_index back when deleting a section before the main product block" do
        @product.update!(sections: [@section.id, @other_section.id], main_section_index: 1)

        delete @action, params: @params

        expect(@product.reload).to have_attributes(
          sections: [@other_section.id],
          main_section_index: 0
        )
      end

      it "does not destroy sections from another product" do
        other_product = create(:product, user: @user)
        other_section = create(:seller_profile_products_section, seller: @user, product: other_product)

        delete @action, params: @params.merge(id: other_section.external_id)

        expect(response.parsed_body).to eq(
          {
            "success" => false,
            "message" => "The section was not found.",
          }
        )
        expect(SellerProfileSection.exists?(other_section.id)).to be(true)
      end
    end
  end
end
