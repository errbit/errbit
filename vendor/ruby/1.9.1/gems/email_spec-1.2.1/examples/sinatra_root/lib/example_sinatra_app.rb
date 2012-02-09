require 'sinatra/base'
require 'pony'

class ExampleSinatraApp < Sinatra::Base
  get '/' do
    <<-EOHTML
  <form method="post" action="/signup">
      <label for="Name">Name</label>
      <input type="text" id="Name" name="user[name]">
      <label for="Email">Email</label>
      <input type="text" id="Email" name="user[email]">
      <input type="submit" value="Sign up">
  </form>
    EOHTML
  end

  post '/signup' do
    user = params[:user]
    body = <<-EOTEXT
  Hello #{user['name']}!

  Copy and paste this URL into your browser to confirm your account!

  http://www.example.com/confirm
  This is the text part.
    EOTEXT
    html_body = <<-EOHTML
  Hello #{user['name']}!

  <a href="http://www.example.com/confirm">Click here to confirm your account!</a>
  This is the HTML part.
    EOHTML
    Pony.mail(:from => 'admin@example.com',
              :to => user['email'],
              :subject => 'Account confirmation',
              :body => body,
              :html_body => html_body
             )
             'Thanks!  Go check your email!'
  end

  get '/confirm' do
    'Confirm your new account!'
  end
end
