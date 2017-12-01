require 'test_helper'
require 'gds_api/test_helpers/content_store'

class ServiceSignInTest < ActiveSupport::TestCase
  include GovukContentSchemaTestHelpers::TestUnit
  include GdsApi::TestHelpers::ContentStore

  def subject
    Formats::ServiceSignInPresenter.new(@content)
  end

  def file_name
    "example.yaml"
  end

  def load_content_from_file(file_name)
    @content ||= YAML.load_file(Rails.root.join("lib", "service_sign_in", file_name)).deep_symbolize_keys
  end

  def setup
    load_content_from_file(file_name)
    @artefact ||= FactoryGirl.create(:artefact, kind: "transaction")
    @parent ||= FactoryGirl.create(
      :transaction_edition,
      panopticon_id: @artefact.id,
      slug: "log-in-file-self-assessment-tax-return"
    )
    content_store_does_not_have_item(base_path)
  end

  def parent_base_path
    "/log-in-file-self-assessment-tax-return"
  end

  def base_path
    "#{parent_base_path}/sign-in"
  end

  def result
    subject.render_for_publishing_api
  end

  should "be valid against schema" do
    assert_valid_against_schema(result, 'service_sign_in')
  end

  context "#content_id" do
    should "create a new content id if we are creating a new content item" do
      SecureRandom.stub :uuid, "random-uuid-string" do
        assert_equal "random-uuid-string", subject.content_id
      end
    end

    should "use existing content_id if content_item already exists in content-store" do
      content_item = content_item_for_base_path(base_path)
      content_item["content_id"] = "content-item-id"
      content_store_has_item(base_path, content_item)

      assert_equal content_item["content_id"], subject.content_id
    end
  end

  should "[:schema_name]" do
    assert_equal 'service_sign_in', result[:schema_name]
  end

  should "[:rendering_app]" do
    assert_equal 'government-frontend', result[:rendering_app]
  end

  should "[:publishing_app]" do
    assert_equal 'publisher', result[:publishing_app]
  end

  should "[:document_type]" do
    assert_equal 'service_sign_in', result[:document_type]
  end

  should "[:locale]" do
    assert_equal @content[:locale], result[:locale]
  end

  should "[:update_type]" do
    assert_equal @content[:update_type], result[:update_type]
  end

  should "[:change_note]" do
    assert_equal @content[:change_note], result[:change_note]
  end

  should "[:base_path]" do
    assert_equal base_path, result[:base_path]
  end

  should "[:routes]" do
    expected = [
      { path: base_path, type: "prefix" },
    ]
    assert_equal expected, result[:routes]
  end

  should "[:title]" do
    assert_equal @parent.title, result[:title]
  end

  should "[:description]" do
    assert_equal @parent.overview, result[:description]
  end


  context "[:public_updated_at]" do
    should "return current timestamp when update_type is 'major'" do
      Timecop.freeze do
        assert_equal DateTime.now.rfc3339, result[:public_updated_at]
      end
    end

    should "return public_updated_at from content-store when update_type is not 'major'" do
      @content[:update_type] = "minor"
      content_store_has_item(base_path)
      content_item = content_item_for_base_path(base_path)
      assert_equal content_item["public_updated_at"], result[:public_updated_at]
    end
  end

  should "#links" do
    expected = {
      parent: [@parent.content_id]
    }

    assert_equal expected, subject.links
  end

  context "[:details]" do
    context "[:choose_sign_in]" do
      should "[:title]" do
        assert_equal @content[:choose_sign_in][:title],
          result[:details][:choose_sign_in][:title]
      end

      should "[:slug]" do
        assert_equal @content[:choose_sign_in][:slug],
          result[:details][:choose_sign_in][:slug]
      end

      should "[:description]" do
        expected = [
          {
            content_type: "text/govspeak",
            content: @content[:choose_sign_in][:description]
          }
        ]
        assert_equal expected, result[:details][:choose_sign_in][:description]
      end

      should "[:options]" do
        option_one = @content[:choose_sign_in][:options][0]
        option_two = @content[:choose_sign_in][:options][1]
        option_three = @content[:choose_sign_in][:options][2]
        expected = [
          {
            text: option_one[:text],
            url: option_one[:url],
            hint_text: option_one[:hint_text],
          },
          {
            text: option_two[:text],
            url: option_two[:url],
            hint_text: option_two[:hint_text],
          },
          {
            text: option_three[:text],
            url: "#{base_path}/#{option_three[:slug]}",
          },
        ]
        assert_equal expected, result[:details][:choose_sign_in][:options]
      end
    end

    context "[:create_new_account]" do
      should "[:title]" do
        assert_equal @content[:create_new_account][:title],
          result[:details][:create_new_account][:title]
      end

      should "[:slug]" do
        assert_equal @content[:create_new_account][:slug],
          result[:details][:create_new_account][:slug]
      end

      should "[:body]" do
        expected = [
          {
            content_type: "text/govspeak",
            content: @content[:create_new_account][:body],
          }
        ]

        assert_equal expected, result[:details][:create_new_account][:body]
      end
    end
  end
end
