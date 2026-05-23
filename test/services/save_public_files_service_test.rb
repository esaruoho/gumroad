# frozen_string_literal: true

require "test_helper"

class SavePublicFilesServiceTest < ActiveSupport::TestCase
  setup do
    @product = links(:save_public_files_product)
    @public_file1 = public_files(:save_public_file_one)
    @public_file2 = public_files(:save_public_file_two)
  end

  test "#process updates existing files and returns cleaned content" do
    files_params = [
      { "id" => @public_file1.public_id, "name" => "Updated Audio 1", "status" => { "type" => "saved" } },
      { "id" => @public_file2.public_id, "name" => "", "status" => { "type" => "saved" } },
      { "id" => "blob:http://example.com/audio.mp3", "name" => "Audio 3", "status" => { "type" => "uploading" } },
    ]

    result = SavePublicFilesService.new(resource: @product, files_params:, content:).process

    assert_equal ["Updated Audio 1", nil], @public_file1.reload.attributes.values_at("display_name", "scheduled_for_deletion_at")
    assert_equal ["Untitled", nil], @public_file2.reload.attributes.values_at("display_name", "scheduled_for_deletion_at")
    assert_equal 2, @product.public_files.alive.count
    assert_equal content, result
  end

  test "#process schedules unused files for deletion" do
    product = links(:save_public_files_unused_product)
    used_file = public_files(:save_public_unused_file_one)
    unused_file = public_files(:save_public_unused_file_three)
    embedded_unused_file = public_files(:save_public_unused_file_two)
    files_params = [
      { "id" => used_file.public_id, "name" => "Audio 1", "status" => { "type" => "saved" } },
    ]

    SavePublicFilesService.new(resource: product, files_params:, content: content_for(used_file, embedded_unused_file)).process

    assert_equal 3, product.public_files.alive.count
    assert_scheduled_for_deletion unused_file
    assert_nil used_file.reload.scheduled_for_deletion_at
    assert_scheduled_for_deletion embedded_unused_file
  end

  test "#process removes invalid file embeds from content" do
    content_with_invalid_embeds = <<~HTML
      <p>Some text</p>
      <public-file-embed id="#{@public_file1.public_id}"></public-file-embed>
      <p>Middle text</p>
      <public-file-embed id="nonexistent"></public-file-embed>
      <public-file-embed></public-file-embed>
      <p>More text</p>
    HTML
    files_params = [
      { "id" => @public_file1.public_id, "name" => "Audio 1", "status" => { "type" => "saved" } },
      { "id" => @public_file2.public_id, "name" => "Audio 2", "status" => { "type" => "saved" } },
    ]

    result = SavePublicFilesService.new(resource: @product, files_params:, content: content_with_invalid_embeds).process

    assert_equal <<~HTML, result
      <p>Some text</p>
      <public-file-embed id="#{@public_file1.public_id}"></public-file-embed>
      <p>Middle text</p>


      <p>More text</p>
    HTML
    assert_equal 2, @product.public_files.alive.count
    assert_nil @public_file1.reload.scheduled_for_deletion_at
    assert_scheduled_for_deletion @public_file2
  end

  test "#process handles empty files_params" do
    result = SavePublicFilesService.new(resource: @product, files_params: nil, content:).process

    assert_equal <<~HTML, result
      <p>Some text</p>

      <p>Hello world!</p>

      <p>More text</p>
    HTML
    assert @public_file1.reload.scheduled_for_deletion_at.present?
    assert @public_file2.reload.scheduled_for_deletion_at.present?
  end

  test "#process handles empty content" do
    files_params = [
      { "id" => @public_file1.public_id, "status" => { "type" => "saved" } },
    ]

    result = SavePublicFilesService.new(resource: @product, files_params:, content: nil).process

    assert_equal "", result
    assert @public_file1.reload.scheduled_for_deletion_at.present?
    assert @public_file2.reload.scheduled_for_deletion_at.present?
  end

  test "#process rolls back on error" do
    files_params = [
      { "id" => @public_file1.public_id, "name" => "Updated Audio 1", "status" => { "type" => "saved" } },
    ]

    with_public_file_save_failure(@public_file1.public_id) do
      assert_raises(ActiveRecord::RecordInvalid) do
        SavePublicFilesService.new(resource: @product, files_params:, content:).process
      end
    end

    assert_equal "Audio 1", @public_file1.reload.display_name
    assert_nil @public_file1.scheduled_for_deletion_at
    assert_nil @public_file2.reload.scheduled_for_deletion_at
  end

  private
    def content
      content_for(@public_file1, @public_file2)
    end

    def content_for(public_file1, public_file2)
      <<~HTML
        <p>Some text</p>
        <public-file-embed id="#{public_file1.public_id}"></public-file-embed>
        <p>Hello world!</p>
        <public-file-embed id="#{public_file2.public_id}"></public-file-embed>
        <p>More text</p>
      HTML
    end

    def assert_scheduled_for_deletion(public_file)
      assert_in_delta 10.days.from_now.to_i, public_file.reload.scheduled_for_deletion_at.to_i, 5
    end

    def with_public_file_save_failure(public_id)
      original_save = PublicFile.instance_method(:save!)
      PublicFile.define_method(:save!) do |*args, **kwargs, &block|
        raise ActiveRecord::RecordInvalid.new(self) if self.public_id == public_id

        original_save.bind(self).call(*args, **kwargs, &block)
      end
      yield
    ensure
      PublicFile.define_method(:save!, original_save)
    end
end
