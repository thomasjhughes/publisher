# Be sure to restart your server when you modify this file.

Rails.application.config.session_store :cookie_store,
  key: '_publisher_session',
  secure: false,
  http_only: true
