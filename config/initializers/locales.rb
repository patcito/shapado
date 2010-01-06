I18n.backend.store_translations 'es-AR', {}
I18n.backend.store_translations 'en', {}
I18n.backend.store_translations 'fr', {}
I18n.backend.store_translations 'pt-PT', {}

I18n.load_path << Dir[ File.join(RAILS_ROOT, 'config', 'locales', '**', '*.{rb,yml}') ]

# You need to "force-initialize" loaded locales
I18n.backend.send(:init_translations)

AVAILABLE_LOCALES = I18n.backend.available_locales
AVAILABLE_LANGUAGES = I18n.backend.available_locales.map { |l| l.to_s.split("-").first}.uniq
RAILS_DEFAULT_LOGGER.debug "* Loaded locales: #{AVAILABLE_LOCALES.inspect}"
