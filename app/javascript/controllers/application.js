import { Application } from "@hotwired/stimulus"

import RevealController from '@stimulus-components/reveal'
import CheckboxSelectAll from '@stimulus-components/checkbox-select-all'

const application = Application.start()

application.register("reveal", RevealController)
application.register("checkbox-select-all", CheckboxSelectAll)

// Configure Stimulus development experience
application.debug = true
window.Stimulus   = application

export { application }
