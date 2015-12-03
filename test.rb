require 'i18n'
I18n.load_path = Dir['config/locales/*.yml']
puts I18n.config.locale
puts I18n.t('params.host.url')
