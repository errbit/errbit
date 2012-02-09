# MongoDB Ruby Driver Release Plan

This is a description of a formalized release plan that will take effect
with version 1.3.0.

## Semantic versioning

The most significant difference is that releases will now adhere to the conventions of
[semantic versioning](http://semver.org). In particular, we will strictly abide by the
following release rules:

1. Patch versions of the driver (Z in x.y.Z) will be released only when backward-compatible bug fixes are introduced. A bug fix is defined as an internal change that fixes incorrect behavior.

2. Minor versions (Y in x.Y.z) will be released if new, backward-compatible functionality is introduced to the public API.

3. Major versions (X in X.y.z) will be incremented if any backward-incompatibl changes are introduced to the public API.

This policy will clearly indicate to users when an upgrade may affect their code. As a side effect, version numbers will climb more quickly than before.


## Release checklist

Before each relese to Rubygems.org, the following steps will be taken:

1. All driver tests will be run on Linux, OS X, and Windows via continuous integration system.

2. HISTORY file will document all significant commits.

3. Version number will be incremented per the semantic version spec described above.

4. Appropriate branches and tags will be created in Git repository, as necessary.

5. Docs will be updated to the latest version of the driver and posted [online](http://api.mongodb.org/ruby/current/index.html).
