# frozen_string_literal: true

require "test_helper"

class UsernameGeneratorServiceTest < ActiveSupport::TestCase
  def stub_completion(generator, value)
    seq = Array(value).dup
    generator.define_singleton_method(:openai_completion) { seq.shift || seq.last }
  end

  test "adds numbers to the end if the username already exists" do
    existing = users(:basic_user)
    existing.update!(username: "johnsmith")

    user = User.new(email: "johnsmith@gmail.com")
    generator = UsernameGeneratorService.new(user)
    stub_completion(generator, "johnsmith")

    g1 = generator.username
    assert_match(/\Ajohnsmith\d\z/, g1)
    User.new(email: "j2-#{SecureRandom.hex(2)}@example.com").tap { |u| u.username = g1; u.save!(validate: false) }

    # Reset the stub for the next call.
    stub_completion(generator, "johnsmith")
    g2 = generator.username
    ends_diff = g1[-1] != g2[-1]
    ends_two = g2 =~ /\Ajohnsmith\d\d\z/
    assert(ends_diff || ends_two)
  end

  test "returns nil when user has no name or email" do
    user = User.new(email: nil, name: nil)
    assert_nil UsernameGeneratorService.new(user).username
  end

  test "generates a valid username when openai returns only numbers" do
    user = User.new(email: "x@example.com")
    generator = UsernameGeneratorService.new(user)
    stub_completion(generator, "123")
    assert_equal "123a", generator.username
  end

  test "generates a valid username when openai returns blank" do
    user = User.new(email: "x@example.com")
    generator = UsernameGeneratorService.new(user)
    stub_completion(generator, "")
    assert_match(/\Aa\d\d\z/, generator.username)
  end

  test "strips capital letters and invalid characters" do
    user = User.new(email: "x@example.com")
    generator = UsernameGeneratorService.new(user)
    stub_completion(generator, "John_Smith")
    assert_equal "johnsmith", generator.username
  end

  test "pads when openai returns a username that is too short" do
    user = User.new(email: "x@example.com")
    generator = UsernameGeneratorService.new(user)
    stub_completion(generator, "hi")
    assert_match(/\Ahi\d\z/, generator.username)
  end

  test "truncates when openai returns a username that is too long" do
    user = User.new(email: "x@example.com")
    generator = UsernameGeneratorService.new(user)
    stub_completion(generator, "areallyreallylongusername")
    assert_equal "areallyreallylonguse", generator.username
  end

  test "suffixes a digit when openai returns a DENYLIST word" do
    user = User.new(email: "x@example.com")
    generator = UsernameGeneratorService.new(user)
    stub_completion(generator, "about")
    assert_match(/\Aabout\d\z/, generator.username)
  end
end
