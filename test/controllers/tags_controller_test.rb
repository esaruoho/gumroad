# frozen_string_literal: true

require "test_helper"

class TagsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test "GET index shows matching tags alphabetically" do
    %w[Armadillo Antelope Marmoset Aardvark].each { |animal| Tag.create!(name: animal) }
    get :index, params: { text: "a" }
    body = response.parsed_body
    assert_equal 3, body.length
    assert_equal "aardvark", body.first["name"]
    assert_equal 0, body.first["uses"]
    assert_equal "armadillo", body.last["name"]
    assert_equal 0, body.last["uses"]
  end

  test "GET index shows popular tags first" do
    porcupine = Tag.create!(name: "Porcupine")
    pangolin = Tag.create!(name: "Pangolin")
    porcupine_products = %i[named_seller_product another_seller_product basic_user_product
                            recommended_product_one recommended_product_two].map { |k| links(k) }
    pangolin_products = %i[recommended_product_three audience_physical_product].map { |k| links(k) }
    porcupine_products.each { |p| ProductTagging.create!(product: p, tag: porcupine) }
    pangolin_products.each { |p| ProductTagging.create!(product: p, tag: pangolin) }

    get :index, params: { text: "p" }
    body = response.parsed_body
    assert_equal "porcupine", body.first["name"]
    assert_equal 5, body.first["uses"]
    pang = body.find { |t| t["name"] == "pangolin" }
    assert_equal 2, pang["uses"]
  end

  test "GET index returns success false if no text is passed in" do
    get :index
    assert_equal false, response.parsed_body["success"]
  end
end
