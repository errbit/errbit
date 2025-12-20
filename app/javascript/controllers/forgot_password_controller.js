// <script>
//     $("a#forgot_password").click(function(){
//     // Set email field on password reset page to email that user entered on this page
//     location.href = $(this).attr("href") + "?email=" + encodeURIComponent($("#user_email").val());
//
//     return false;
// });
// </script>

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [ "auth_key", "href" ]

    click(event) {
        event.preventDefault()

        Turbo.visit(`${this.hrefTarget.href}?email=${this.auth_keyTarget.value}`, { action: "advance" })
    }
}
