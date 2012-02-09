# ruby-fogbugz

A very simple wrapper for the Fogbugz API. It won't give you fancy classes for everything, it'll simply aid you in sending the API requests, parsing the returned XML finally retuning you a Hash.

# Installation

    gem install ruby-fogbugz

```ruby
["mri-1.9,2", "mri-1.8.7", "rbx-1.2.4", "rbx-2.0.0", "jruby-1.6.2"].all? { |implementation| implementation.works? }
# => true
```

# Usage

The Fogbugz API works by sending HTTP GET parameters to the API where the GET parameter `cmd` invokes a Fogbugz method, e.g. `cmd=listProjects` to get a list of all projects, `cmd`s then accept further arguments, such as listing all cases assigned to a specific person:

    cmd=search&ixAssignedTo=2&cols=sTitle,sStatus # list all cases associated to the user with ID of 2 in Fogbugz

In `ruby-fogbugz` that request would be:

```ruby
fogbugz.command(:search, :ixAssignedTo => 2, :cols => "sTitle,sStatus")
```

Returns your parsed XML:

```ruby
{
  "description"=>"All open cases assigned to Simon Eskildsen",
  "cases" => {
    "case"=> [
      {"ixBug"=>"143", "sTitle"=>"Write ruby-fogbugz documentation", 
      "sStatus"=>"active", "operations"=>"edit,assign,resolve,email,remind"},
      {"ixBug"=>"146", "sTitle"=>"Tame a unicorn", "sStatus"=>"active", 
      "operations"=>"edit,assign,resolve,email,remind"},
      {"ixBug"=>"152", "sTitle"=>"Hug a walrus", "sStatus"=>"active", 
      "operations"=>"edit,assign,resolve,email,remind"},
    ], "count"=>"3"
  }
}
```

As you see, `ruby-fogbugz` is without magic and leaves most to the user.

`cmd` is the first argument to `Fogbugz#command`, the second argument being a `Hash` of additional GET arguments to specify the request further. You can see available `cmd`'s and arguments at the [Fogbugz API documentation][fad].

All Fogbugz API requests require a token. Thus `#authenticate` must be called on the `ruby-fogbugz` instance before `#command`'s are sent:

```ruby
require 'rubygems'
require 'fogbugz'
require 'pp'

fogbugz = Fogbugz::Interface.new(:email => 'my@email.com', :password => 'seekrit', :uri => 'https://company.fogbugz.com') # remember to use https!
fogbugz.authenticate # token is not automatically attached to every future requests
pp fogbugz.command(:listPeople)
```

[fad]:http://fogbugz.stackexchange.com/fogbugz-xml-api

# License

`ruby-fogbugz` is released under the MIT license.
