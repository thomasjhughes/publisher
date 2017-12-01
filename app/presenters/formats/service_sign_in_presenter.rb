module Formats
  class ServiceSignInPresenter
    attr_reader :content

    def initialize(content)
      @content = content
    end

    def render_for_publishing_api
      {
        schema_name: "service_sign_in",
        rendering_app: "government-frontend",
        publishing_app: "publisher",
        document_type: "service_sign_in",
        locale: locale,
        update_type: update_type,
        change_note: change_note,
        base_path: base_path,
        routes: routes,
        title: title,
        description: description,
        public_updated_at: public_updated_at,
        details: details,
      }
    end

    def content_id
      begin
        content_item["content_id"]
      rescue GdsApi::ContentStore::ItemNotFound
        SecureRandom.uuid
      end
    end

    def links
      {
        parent: [parent.content_id]
      }
    end

  private

    def locale
      content[:locale]
    end

    def update_type
      content[:update_type]
    end

    def change_note
      content[:change_note]
    end

    def base_path
      "/#{parent_slug}/sign-in"
    end

    def routes
      [
        { path: base_path.to_s, type: "prefix" },
      ]
    end

    def title
      parent.title
    end

    def description
      parent.overview
    end

    def public_updated_at
      return DateTime.now.rfc3339 if update_type == "major"
      content_item["public_updated_at"]
    end

    def details
      {
        choose_sign_in: choose_sign_in,
        create_new_account: create_new_account,
      }
    end

    def choose_sign_in
      {
        title: content[:choose_sign_in][:title],
        slug: content[:choose_sign_in][:slug],
        description: [
          {
            content_type: "text/govspeak",
            content: content[:choose_sign_in][:description]
          }
        ],
        options: options,
      }
    end

    def options
      options = content[:choose_sign_in][:options]
      options.each do |option|
        if option.key?(:slug)
          option[:slug] = "#{base_path}/#{option[:slug]}"
          option[:url] = option.delete :slug
        end
      end
    end

    def create_new_account
      {
        title: content[:create_new_account][:title],
      }
    end

    def content_item
      @content_item ||= Services.content_store.content_item(base_path)
    end

    def parent
      @parent ||= Edition.where(slug: parent_slug).last
    end

    def parent_slug
      content[:start_page_slug]
    end
  end
end
