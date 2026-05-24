# frozen_string_literal: true

require "test_helper"

class QstValidationServiceTest < ActiveSupport::TestCase
  setup { Rails.cache.clear }
  teardown { Rails.cache.clear }

  QST_ID = "1002092821TQ0001"

  test "returns true when a valid qst id is provided" do
    WebMock.stub_request(:get, "https://svcnab2b.revenuquebec.ca/2019/02/ValidationTVQ/#{QST_ID}")
      .to_return(status: 200, body: {
        "Resultat" => { "StatutSousDossierUsager" => "R", "NomEntreprise" => "APPLE CANADA INC." },
        "OperationReussie" => true
      }.to_json, headers: { "Content-Type" => "application/json;charset=utf-8" })

    assert_equal true, QstValidationService.new(QST_ID).process
  end

  test "returns false when the qst id is nil" do
    assert_equal false, QstValidationService.new(nil).process
  end

  test "returns false when the qst id is empty" do
    assert_equal false, QstValidationService.new("").process
  end

  test "returns false when the format of the qst id is invalid" do
    WebMock.stub_request(:get, "https://svcnab2b.revenuquebec.ca/2019/02/ValidationTVQ/NR00005576")
      .to_return(status: 200, body: { "Resultat" => nil, "OperationReussie" => false }.to_json,
                 headers: { "Content-Type" => "application/json;charset=utf-8" })
    assert_equal false, QstValidationService.new("NR00005576").process
  end

  test "returns false when the qst id is not a registration number" do
    bad_id = QST_ID.gsub("0001", "0002")
    WebMock.stub_request(:get, "https://svcnab2b.revenuquebec.ca/2019/02/ValidationTVQ/#{bad_id}")
      .to_return(status: 200, body: { "Resultat" => nil, "OperationReussie" => false }.to_json,
                 headers: { "Content-Type" => "application/json;charset=utf-8" })
    assert_equal false, QstValidationService.new(bad_id).process
  end

  test "returns false when the qst id registration has been revoked or cancelled" do
    revoked_result = {
      "Resultat" => {
        "StatutSousDossierUsager" => "A",
        "DescriptionStatut" => "Regulier",
        "DateStatut" => "1992-07-01T00:00:00",
        "NomEntreprise" => "APPLE CANADA INC.",
        "RaisonSociale" => nil
      },
      "OperationReussie" => true,
      "MessagesFonctionnels" => [],
      "MessagesInformatifs" => []
    }
    revoked_response = Minitest::Mock.new
    revoked_response.expect(:code, 200)
    revoked_response.expect(:parsed_response, revoked_result)

    HTTParty.stub(:get, ->(url, **_opts) {
      assert_equal "https://svcnab2b.revenuquebec.ca/2019/02/ValidationTVQ/#{QST_ID}", url
      revoked_response
    }) do
      assert_equal false, QstValidationService.new(QST_ID).process
    end
    revoked_response.verify
  end

  test "handles QST IDs that need encoding" do
    # blank-after-encoding-or-other invalid: just stub any GET to return an empty result
    WebMock.stub_request(:get, %r{svcnab2b\.revenuquebec\.ca}).to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })
    assert_equal false, QstValidationService.new("needs encoding").process
  end
end
