architecture :rails

component :interactors, in: "app/interactors/**/*.rb"
component :decorators, in: "app/decorators/**/*.rb"
component :policies, in: "app/policies/**/*.rb"
component :app_lib, in: "app/lib/**/*.rb"

models.cannot_use :controllers, :interactors, :decorators, :policies
interactors.cannot_use :controllers, :helpers, :decorators
decorators.cannot_use :controllers, :interactors, :policies
policies.cannot_use :controllers, :interactors, :decorators
app_lib.cannot_use :controllers, :models, :interactors, :decorators, :policies
