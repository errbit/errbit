Lighthouse API
--------------

The official Ruby library for interacting with the [Lighthouse REST API](http://lighthouseapp.com/api). 

### Documentation & Requirements
* ActiveResource 
* ActiveSupport

Check out lib/lighthouse.rb for examples and documentation.


### Using The Lighthouse Console

The Lighthouse library comes with a convenient console for testing and quick commands 
(or whatever else you want to use it for).

From /lib:

    # For ruby 1.9
    # irb -I. -r lighthouse/console.rb
    
    irb -r lighthouse/console
    
    Lighthouse.account = "activereload"

    #### You can use `authenticate` OR `token`
    Lighthouse.authenticate('username', 'password')
    #Lighthouse.token = 'YOUR_TOKEN'
    
    Project.find(:all)
    
### Contributions
 * technoweenie (rick)
 * caged (Justin Palmer)
 * granth (Grant Hollingworth)
 * kneath (Kyle Neath)
 * djanowski (Damian Janowski)
 * drnic (Dr Nic Williams)
 * texel (Leigh Caplan)
 * trptcolin (Colin Jones)
 * cyberfox (Morgan Schweers)
 * krekoten (Крекотень Мар'ян)


