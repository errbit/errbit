import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [ "auth_key", "href" ]

    click(event) {
        event.preventDefault()

        Turbo.visit(`${this.hrefTarget.href}?email=${this.auth_keyTarget.value}`, { action: "advance" })
    }
}
