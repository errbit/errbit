# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

# Enable integrity calculation globally
enable_integrity!

pin "application"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

pin_all_from "app/javascript/controllers", under: "controllers"

pin "@rails/ujs", to: "@rails--ujs.js" # @7.1.3

pin "@popperjs/core", to: "popper.js", preload: false # @2.11.8
pin "bootstrap", to: "bootstrap.esm.min.js", preload: false # @5.3.8

pin "@stimulus-components/reveal", to: "@stimulus-components--reveal.js" # @5.0.0
pin "@stimulus-components/checkbox-select-all", to: "@stimulus-components--checkbox-select-all.js" # @6.1.0
