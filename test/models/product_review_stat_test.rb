# frozen_string_literal: true

require "test_helper"

class ProductReviewStatTest < ActiveSupport::TestCase
  # --- #rating_counts ---

  test "rating_counts returns counts of ratings" do
    stat = ProductReviewStat.new(link: links(:review_stat_test_product_a), ratings_of_one_count: 7, ratings_of_three_count: 11)
    assert_equal({ 1 => 7, 2 => 0, 3 => 11, 4 => 0, 5 => 0 }, stat.rating_counts)
  end

  # --- #rating_percentages ---

  test "rating_percentages returns zero when there are no ratings" do
    stat = ProductReviewStat.new(link: links(:review_stat_test_product_a))
    assert_equal({ 1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0 }, stat.rating_percentages)
  end

  test "rating_percentages returns percentages" do
    stat = ProductReviewStat.new(link: links(:review_stat_test_product_a), reviews_count: 4, ratings_of_one_count: 1, ratings_of_three_count: 3)
    assert_equal({ 1 => 25, 2 => 0, 3 => 75, 4 => 0, 5 => 0 }, stat.rating_percentages)
  end

  test "rating_percentages adjusts non-integer values to total 100" do
    stat = ProductReviewStat.new(
      link: links(:review_stat_test_product_a),
      reviews_count: 4 + 3 + 7 + 12 + 428,
      ratings_of_one_count: 4,
      ratings_of_two_count: 3,
      ratings_of_three_count: 7,
      ratings_of_four_count: 12,
      ratings_of_five_count: 428,
    )
    assert_equal({ 1 => 1, 2 => 1, 3 => 1, 4 => 3, 5 => 94 }, stat.rating_percentages)
  end

  test "rating_percentages favors higher star ratings if there are ties" do
    stat = ProductReviewStat.new(
      link: links(:review_stat_test_product_a),
      reviews_count: 3,
      ratings_of_one_count: 1,
      ratings_of_three_count: 1,
      ratings_of_five_count: 1,
    )
    assert_equal({ 1 => 33, 2 => 0, 3 => 33, 4 => 0, 5 => 34 }, stat.rating_percentages)
  end

  # --- #update_with_added_rating ---

  test "update_with_added_rating correctly updates target & derived columns" do
    stat = ProductReviewStat.create!(link: links(:review_stat_test_product_a))
    stat.update_with_added_rating(2)
    assert_attrs(stat, ratings_of_two_count: 1, reviews_count: 1, average_rating: 2.0)

    stat.update_with_added_rating(4)
    stat.update_with_added_rating(2)
    assert_attrs(stat, ratings_of_two_count: 2, ratings_of_four_count: 1, reviews_count: 3, average_rating: 2.7)
  end

  # --- #update_with_changed_rating ---

  test "update_with_changed_rating correctly updates target & derived columns" do
    stat = ProductReviewStat.create!(link: links(:review_stat_test_product_b), ratings_of_five_count: 3, reviews_count: 3, average_rating: 5.0)
    stat.update_with_changed_rating(5, 4)
    assert_attrs(stat, ratings_of_four_count: 1, ratings_of_five_count: 2, reviews_count: 3, average_rating: 4.7)
  end

  # --- #update_with_removed_rating ---

  test "update_with_removed_rating correctly updates target & derived columns" do
    stat = ProductReviewStat.create!(link: links(:review_stat_test_product_c), ratings_of_four_count: 1, ratings_of_five_count: 2, reviews_count: 3, average_rating: (4 + 5 + 5) / 3.0)
    stat.update_with_removed_rating(5)
    assert_attrs(stat, ratings_of_four_count: 1, ratings_of_five_count: 1, reviews_count: 2, average_rating: 4.5)
  end

  # --- #update_ratings (private) ---

  test "update_ratings updates reviews_count and average_rating appropriately" do
    stat = ProductReviewStat.create!(link: links(:review_stat_test_product_d))
    stat.send(:update_ratings, "
      ratings_of_one_count = 5,
      ratings_of_two_count = 10,
      ratings_of_three_count = 20,
      ratings_of_four_count = 60,
      ratings_of_five_count = 100
    ")
    assert_attrs(stat,
      ratings_of_one_count: 5,
      ratings_of_two_count: 10,
      ratings_of_three_count: 20,
      ratings_of_four_count: 60,
      ratings_of_five_count: 100,
      reviews_count: 195,
      average_rating: 4.2,
    )
  end

  test "TODO: review stat updated after purchase fully refunded — VCR Stripe path" do
    skip "Requires VCR/Stripe purchase processing + product_reviews factory chain — skip-batch."
  end

  private
    def assert_attrs(stat, **attrs)
      defaults = {
        ratings_of_one_count: 0,
        ratings_of_two_count: 0,
        ratings_of_three_count: 0,
        ratings_of_four_count: 0,
        ratings_of_five_count: 0,
      }
      expected = defaults.merge(attrs).transform_keys(&:to_s)
      assert_equal expected, stat.attributes.slice(*expected.keys)
    end
end
