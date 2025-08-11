Rails.application.config.session_store :cookie_store,
  key: '_ilscatcher4_session',
  same_site: :none,   # REQUIRED for iframes on other domains
  secure: true        # required when same_site: :none

Rails.application.config.action_dispatch.cookies_same_site_protection = :none