# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Cart spec (198 LOC, 41 create() refs) covers
# alive_cart_products / cart_products / abandoned-cart query scopes and
# email-vs-user resolution. Every assertion threads through `create(:cart_product)`
# which itself creates a Cart + Link + Variant; the abandoned-cart matrix
# also requires cart.email-only carts and `AbandonedCartWorker` enqueue
# assertions. ~5 new cart-related fixture tables (carts, cart_products,
# cart_offers) needed. Out of scope for mechanical model backfill.
#
# Original spec: spec/models/cart_spec.rb
class CartTest < ActiveSupport::TestCase
  test "TODO: migrate — Cart + CartProduct + AbandonedCartWorker enqueue" do
    skip "41 create() refs through Cart + CartProduct + Variant + abandoned-cart query matrix; needs carts/cart_products fixture tables. Out of scope for mechanical model backfill."
  end
end
