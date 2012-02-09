# ActionMailer Inline CSS [![TravisCI](http://travis-ci.org/ndbroadbent/actionmailer_inline_css.png?branch=master)](http://travis-ci.org/ndbroadbent/actionmailer_inline_css)

Seamlessly integrate [Alex Dunae's premailer](http://premailer.dialect.ca/) gem with ActionMailer.


## Problem?

Gmail doesn't support `<style>` or `<link>` tags for HTML emails. Other webmail clients also
have problems with `<link>` tags.

This means that CSS must be inlined on each element, otherwise
the email will not be displayed correctly in every client.


## Solution

Inlining CSS is a pain to do by hand, and that's where the
[premailer](http://premailer.dialect.ca/) gem comes in.

From http://premailer.dialect.ca/:

* CSS styles are converted to inline style attributes.
  Checks <tt>style</tt> and <tt>link[rel=stylesheet]</tt> tags, and preserves existing inline attributes.
* Relative paths are converted to absolute paths.
  Checks links in <tt>href</tt>, <tt>src</tt> and CSS <tt>url('')</tt>


This <tt>actionmailer_inline_css</tt> gem is a tiny integration between ActionMailer and premailer.

Inspiration comes from [@fphilipe](https://github.com/fphilipe)'s
[premailer-rails3](https://github.com/fphilipe/premailer-rails3) gem, but I wasn't
completely happy with it's conventions.


## Installation & Usage

To use this in your Rails app, simply add `gem "actionmailer_inline_css"` to your `Gemfile`.

* If you already have an HTML email template, all CSS will be automatically inlined.
* If you don't include a text email template, <tt>premailer</tt> will generate one from the HTML part.
  (Having said that, it is recommended that you write your text templates by hand.)

#### NOTE:

The current version of premailer doesn't support UTF-8, so I have written a small
workaround to enforce it. This works for both Ruby 1.9 and 1.8.


### Including CSS in Mail Templates

You can use the `stylesheet_link_tag` helper to add stylesheets to your mailer layouts.
<tt>actionmailer_inline_css</tt> contains a <tt>premailer</tt> override that properly handles
these CSS URIs.

#### Example

Add the following line to the `<head>` section of <tt>app/views/layouts/build_mailer.html.erb</tt>:

    <%= stylesheet_link_tag '/stylesheets/mailers/build_mailer' %>

This will add a stylesheet link for <tt>public/stylesheets/mailers/build_mailer.css</tt>.
Premailer will then inline the CSS from that file, and remove the link tag.


## More Info

See this [Guide to CSS support in email](http://www.campaignmonitor.com/css/) from
[campaignmonitor.com](http://www.campaignmonitor.com) for more info about CSS in emails.


### [Email Client Popularity](http://www.campaignmonitor.com/stats/email-clients/):

| Outlook | 27.62% |
|------:|:------------|
| iOS Devices | 16.01% |
| Hotmail | 12.14% |
| Apple Mail | 11.13% |
| Yahoo! Mail | 9.54% |
| Gmail | 7.02% |

