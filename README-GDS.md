# GOV.UK Errbit Fork

The main changes in the GDS fork are as follows:

* Add GDS signon integration

* Disable some integrations

  Errbit has integrations with pivotal tracker and some other tools. We've
  deliberately disabled them because we don't want to allow sensitive data
  to be leaked out of errbit (which these integrations would allow).

* Allow users to see all apps

  In upstream errbit you can only see apps which you're watching. We want
  users to see all apps in the web interface but only watch some of them.

* Various boilerplate/small integrations (several commits)

## How to keep up-to-date with upstream

It will be cleaner if we can maintain our fork by rebasing our commits on top
of the upstream branch.

Suggested procedure TBD.
