# frozen_string_literal: true

namespace :errbit do
  task "i18n:check" => :environment do
    catalogs = Errbit::Locales.selectable
    abort "No selectable locale catalogs found" if catalogs.empty?

    puts "Validated #{catalogs.size} locale catalog(s): #{catalogs.map(&:identifier).join(", ")}"
  rescue Errbit::Locales::CatalogError => error
    abort error.message
  end
end
