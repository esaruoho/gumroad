# frozen_string_literal: true

require "test_helper"

class SaveFilesServiceTest < ActiveSupport::TestCase
  setup do
    @product = links(:basic_user_product)
  end

  test ".perform with empty params does not raise an error" do
    SaveFilesService.perform(@product, {})
  end

  test "updates files" do
    file_1 = ProductFile.create!(link: @product, description: "pencil", url: "#{S3_BASE_URL}attachment/pencil.png")
    file_2 = ProductFile.create!(link: @product, description: "manual", url: "#{S3_BASE_URL}attachment/manual.pdf")

    SaveFilesService.perform(@product, {
                               files: [
                                 {
                                   external_id: file_2.external_id,
                                   url: file_2.url,
                                   display_name: "new manual",
                                   description: "new manual description",
                                   position: 2
                                 },
                                 {
                                   external_id: SecureRandom.uuid,
                                   url: "#{S3_BASE_URL}attachment/book.pdf",
                                   display_name: "new book",
                                   description: "new book description",
                                   position: 1
                                 },
                                 {
                                   external_id: SecureRandom.uuid,
                                   url: "https://www.gumroad.com",
                                   display_name: "new link",
                                   description: "new link description",
                                   extension: "URL",
                                   position: 0
                                 }
                               ]
                             })

    assert_equal 4, @product.product_files.count
    assert_equal 3, @product.product_files.alive.count

    manual_file = @product.product_files.alive[0].reload
    assert_equal "new manual", manual_file.display_name
    assert_equal "new manual description", manual_file.description
    assert_equal 2, manual_file.position

    book_file = @product.product_files.alive[1].reload
    assert_equal "#{S3_BASE_URL}attachment/book.pdf", book_file.url
    assert_equal "#{S3_BASE_URL}attachment/book.pdf", book_file.unique_url_identifier
    assert_equal "new book", book_file.display_name
    assert_equal "new book description", book_file.description
    assert_equal 1, book_file.position

    link_file = @product.product_files.alive[2].reload
    assert_equal "https://www.gumroad.com", link_file.url
    assert_equal "https://www.gumroad.com", link_file.unique_url_identifier
    assert_equal "new link", link_file.display_name
    assert_equal "new link description", link_file.description
    assert_equal true, link_file.external_link?
    assert_equal 0, link_file.position

    pencil_file = @product.product_files[0].reload
    assert_equal true, pencil_file.deleted?
  end

  test "updates subtitles" do
    streamable_video = ProductFile.create!(link: @product, url: "#{S3_BASE_URL}specs/ScreenRecording.mov", filetype: "mov", filegroup: "video")
    listenable_audio = ProductFile.create!(link: @product, url: "#{S3_BASE_URL}specs/magic.mp3", filetype: "mp3", filegroup: "audio")
    non_streamable_video = ProductFile.create!(link: @product, url: "#{S3_BASE_URL}specs/ScreenRecording.mpg", filetype: "mpg", filegroup: "url")
    readable_document = ProductFile.create!(link: @product, url: "#{S3_BASE_URL}specs/billion-dollar-company-chapter-0.pdf", filetype: "pdf", filegroup: "document")

    video_1 = streamable_video
    video_2 = non_streamable_video
    SubtitleFile.create!(product_file: video_1, url: "#{S3_BASE_URL}specs/sample1.srt", language: "English")
    SubtitleFile.create!(product_file: video_2, url: "#{S3_BASE_URL}specs/sample2.srt", language: "English")
    SubtitleFile.create!(product_file: video_2, url: "#{S3_BASE_URL}specs/sample3.srt", language: "English")

    SaveFilesService.perform(@product, {
                               files: [
                                 {
                                   external_id: streamable_video.external_id,
                                   url: streamable_video.url,
                                   subtitle_files: [{ "url" => "https://newurl1.srt", "language" => "new-language1" }]
                                 },
                                 {
                                   external_id: listenable_audio.external_id,
                                   url: listenable_audio.url
                                 },
                                 {
                                   external_id: non_streamable_video.external_id,
                                   url: non_streamable_video.url,
                                   subtitle_files: [{ "url" => "https://newurl2.srt", "language" => "new-language2" }]
                                 },
                                 {
                                   external_id: readable_document.external_id,
                                   url: readable_document.url
                                 },
                               ]
                             })

    assert_equal 4, @product.product_files.count

    video_1_subtitles = video_1.subtitle_files.reload.alive
    assert_equal 1, video_1_subtitles.count
    assert_equal "https://newurl1.srt", video_1_subtitles.first.url
    assert_equal "new-language1", video_1_subtitles.first.language

    video_2_subtitles = video_2.subtitle_files.reload.alive
    assert_equal 1, video_2_subtitles.count
    assert_equal "https://newurl2.srt", video_2_subtitles.first.url
    assert_equal "new-language2", video_2_subtitles.first.language
  end

  test "maps 'name' param to 'display_name' for product files" do
    file = ProductFile.create!(link: @product, url: "#{S3_BASE_URL}attachment/pencil.png")
    SaveFilesService.perform(@product, {
                               files: [{
                                 external_id: file.external_id,
                                 url: file.url,
                                 name: "renamed file",
                               }]
                             })
    assert_equal "renamed file", file.reload.display_name
  end

  test "prefers 'display_name' over 'name' when both are provided" do
    file = ProductFile.create!(link: @product, url: "#{S3_BASE_URL}attachment/pencil.png")
    SaveFilesService.perform(@product, {
                               files: [{
                                 external_id: file.external_id,
                                 url: file.url,
                                 name: "from name",
                                 display_name: "from display_name",
                               }]
                             })
    assert_equal "from display_name", file.reload.display_name
  end

  test "maps 'file_name' param to 'display_name' for product files round trips" do
    file = ProductFile.create!(link: @product, url: "#{S3_BASE_URL}attachment/pencil.png")
    SaveFilesService.perform(@product, {
                               files: [{
                                 external_id: file.external_id,
                                 url: file.url,
                                 file_name: "renamed file",
                               }]
                             })
    assert_equal "renamed file", file.reload.display_name
  end

  test "supports `files` param as an array" do
    seller = users(:named_seller)
    workflow = Workflow.create!(name: "SaveFiles test workflow", seller: seller, workflow_type: Workflow::SELLER_TYPE)
    installment = Installment.create!(
      seller: seller,
      workflow: workflow,
      name: "SaveFiles test installment",
      message: "Hello",
      installment_type: Installment::SELLER_TYPE,
      send_emails: true,
    )
    file1 = ProductFile.create!(installment: installment, url: "#{S3_BASE_URL}attachment/pencil.png")
    file2 = ProductFile.create!(installment: installment, url: "#{S3_BASE_URL}attachment/manual.pdf")

    SaveFilesService.perform(installment, {
                               files: [
                                 {
                                   external_id: file1.external_id,
                                   url: file2.url,
                                   position: 1,
                                   stream_only: false,
                                   subtitle_files: [],
                                 },
                                 {
                                   external_id: file2.external_id,
                                   url: file2.url,
                                   position: 2,
                                   stream_only: false,
                                   subtitle_files: [],
                                 },
                               ]
                             })

    assert_equal 2, installment.product_files.alive.count
    assert_equal [[file1.id, 1, file2.url], [file2.id, 2, file2.url]].sort,
                 installment.product_files.pluck(:id, :position, :url).sort
  end
end
