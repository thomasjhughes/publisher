module Formats
  class ServiceSignInPresenter
    def initialize(content)
      @content = content
    end

    def render_for_publishing_api
      {
        schema_name: "service_sign_in",
      }
    end
  end
end
