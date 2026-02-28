# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

# Enable integrity calculation globally
enable_integrity!

pin "application"
pin "fontawesome"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

pin_all_from "app/javascript/controllers", under: "controllers"

pin "@stimulus-components/reveal", to: "@stimulus-components--reveal.js" # @5.0.0
pin "@fortawesome/fontawesome-svg-core", to: "@fortawesome--fontawesome-svg-core.js" # @7.2.0
pin "@fortawesome/free-solid-svg-icons", to: "@fortawesome--free-solid-svg-icons.js" # @7.2.0
pin "@fortawesome/free-brands-svg-icons", to: "@fortawesome--free-brands-svg-icons.js" # @7.2.0
