Rails3Root::Application.routes.draw do
  root :to => "welcome#index"
  match "/confirm" => "welcome#confirm", :as => :confirm_account
  match "/newsletter" => "welcome#newsletter", :as => :request_newsletter
  match "/attachments" => "welcome#attachments", :as => :request_attachments
  match "/welcome/signup" => "welcome#signup"
end
