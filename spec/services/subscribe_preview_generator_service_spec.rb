# frozen_string_literal: true

require "spec_helper"

describe SubscribePreviewGeneratorService, type: :system, js: true do
  describe "#generate_pngs" do
    before do
      skip "Ferrum::Browser.network.wait_for_idle hangs against the Vite/Inertia preview page; the standalone Chrome instance never reaches network-idle in CI. Tracked in the PR #5082 review thread."
      @user1 = create(:user, name: "User 1", username: "user1")
      @user2 = create(:user, name: "User 2", username: "user2")
      visit user_subscribe_preview_path(@user1.username) # Needed to boot the server
    end

    it "generates a png correctly" do
      images = described_class.generate_pngs([@user1, @user2])
      expect(images.first).to start_with("\x89PNG".b)
      expect(images.second).to start_with("\x89PNG".b)
    end

    it "renders at 2x retina resolution for OpenGraph consumers" do
      images = described_class.generate_pngs([@user1])
      # PNG IHDR width/height are big-endian 32-bit ints at bytes 16-23 of the file.
      width, height = images.first.byteslice(16, 8).unpack("N2")
      expected_width = SubscribePreviewGeneratorService::WIDTH * SubscribePreviewGeneratorService::RETINA_PIXEL_RATIO
      expected_height = SubscribePreviewGeneratorService::HEIGHT.to_i * SubscribePreviewGeneratorService::RETINA_PIXEL_RATIO
      expect(width).to eq(expected_width)
      expect(height).to be_within(SubscribePreviewGeneratorService::RETINA_PIXEL_RATIO).of(expected_height)
    end

    it "always quits the browser on success" do
      expect_any_instance_of(Ferrum::Browser).to receive(:quit)
      described_class.generate_pngs([@user1])
    end

    it "always quits the browser on error" do
      error = "FAILURE"
      expect_any_instance_of(Ferrum::Browser).to receive(:quit)
      allow_any_instance_of(Ferrum::Browser).to receive(:screenshot).and_raise(error)
      expect { described_class.generate_pngs([@user2]) }.to raise_error(error)
    end
  end
end
