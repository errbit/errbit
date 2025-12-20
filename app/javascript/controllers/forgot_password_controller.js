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

    connect() {
        console.log("Bingo!")

        console.log(this.auth_keyTarget.value)

        console.log(this.hrefTarget.href)
    }

    click(event) {
        event.preventDefault()

        console.log("Bingo 222!")

        // console.log(this)
        // console.log(this.element)
        // console.log(this.element.action)
        //
        // console.log(`${this.element.action}?email=${this.auth_keyTarget.value}`)

        console.log(`${this.hrefTarget.href}?email=${this.auth_keyTarget.value}`)

        console.log(1)
        
        Turbo.visit(`${this.hrefTarget.href}?email=${this.auth_keyTarget.value}`, { action: "advance" })

        console.log(2)

        // Turbo.visit(`${this.element.action}?email=${this.auth_keyTarget.value}`)


        // Turbo.visit(`${this.element.action}?email=${this.auth_keyTarget}`)

        // Set email field on password reset page to email that user entered on this page
        // location.href = $(this).attr("href") + "?email=" + encodeURIComponent($("#user_email").val());


        // console.log(this.auth_keyTarget.value)


    }
}
