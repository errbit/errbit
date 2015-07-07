require 'acceptance/acceptance_helper'

feature 'Errbit rejects malformed requests' do

  scenario 'send a malformed requests in the params' do
    expect {
      visit "/users/sign_in?user[password]=%FF%FE%3C%73%63%72%69%70%74%3E%61%6C%65%72%74%28%32%30%33%29%3C%2F%73%63%72%69%70%74%3E"
    }.to_not raise_error
  end

end
