# Overview

For instructions on upgrading to newer versions, visit
[mongoid.org](http://mongoid.org/docs/upgrading.html).

## 2.4.0 \[ In Development \] \[ Branch: master \]

### New Features

* Ranges can now be passed to #where criteria to create a $gte/$lte query under the
  covers. `Person.where(dob: start_date...end_date)`

### Resolved Issues

* \#1333 Fixed errors with custom types that exist in namespaces. (Peter Gumeson)

## 2.3.4 \[ In Development \] \[ Branch: 2.3.0-stable \]

## 2.3.3

### Resolved Issues

* \#1386 Lowered mongo/bson dependency to 1.3

* \#1377 Fix aggregation functions to properly handle nil or indefined values.
  (Maxime Garcia)

* \#1373 Warn if a scope overrides another scope.

* \#1372 Never persist when binding inside of a read attribute for validation.

* \#1364 Fixed reloading of documents with non bson object id ids.

* \#1360 Fixed performance of Mongoid's observer instantiation by hooking into
  Active Support's load hooks, a la AR.

* \#1358 Fixed type error on many to many synchronization when inverse_of is
  set to nil.

* \#1356 $in criteria can now be chained to non-complex criteria on the same
  key without error.

* \#1350, \#1351 Fixed errors in the string conversions of double quotes and
  tilde when paramterizing keys.

* \#1349 Mongoid documents should not blow up when including Enumerable.
  (Jonas Nicklas)

## 2.3.2

### Resolved Issues

* \#1347 Fix embedded matchers when provided a hash value that does not have a
  modifier as a key.

* \#1346 Dup default sorting criteria when calling first/last on a criteria.

* \#1343 When passing no arguments to `Criteria#all_of` return all documents.
  (Chris Leishman)

* \#1339 Ensure destroy callbacks are run on cascadable children when deleting via
  nested attributes.

* \#1324 Setting `inverse_of: nil` on a many-to-many referencing the same class
  returns nil for the inverse foreign key.

* \#1323 Allow both strings and symbols as ids in the attributes array for
  nested attributes. (Michael Wood)

* \#1312 Setting a logger on the config now accepts anything that quacks like a
  logger.

* \#1297 Don't hit the database when accessing relations if the base is new.

* \#1239 Allow appending of referenced relations in create blocks, post default set.

* \#1236 Ensure all models are loaded in rake tasks, so even in threadsafe mode
  all indexes can be created.

* \#736 Calling #reload on embedded documents now works properly.

## 2.3.1

### Resolved Issues

* \#1338 Calling #find on a scope or relation checks that the document in the
  identity map actually matches other scope parameters.

* \#1321 HABTM no longer allows duplicate entries or keys, instead of the previous
  inconsistencies.

* \#1320 Fixed errors in perf benchmark.

* \#1316 Added a separate Rake task "db:mongoid:drop" so Mongoid and AR can coexist.
  (Daniel Vartanov)

* \#1311 Fix issue with custom field serialization inheriting from hash.

* \#1310 The referenced many enumerable target no longer duplicates loaded and
  added documents when the identity map is enabled.

* \#1295 Fixed having multiple includes only execute the eager loading of the first.

* \#1287 Fixed max versions limitation with versioning.

* \#1277 attribute_will_change! properly flags the attribute even if no change occured.

* \#1063 Paranoid documents properly run destroy callbacks on soft destroy.

* \#1061 Raise `Mongoid::Errors::InvalidTime` when time serialization fails.

* \#1002 Check for legal bson ids when attempting conversion.

* \#920 Allow relations to be named target.

* \#905 Return normalized class name in metadata if string was defined with a
  prefixed ::.

* \#861 accepts_nested_attributes_for is no longer needed to set embedded documents
  via a hash or array of hashes directly.

* \#857 Fixed cascading of dependent relations when base document is paranoid.

* \#768 Fixed class_attribute definitions module wide.

* \#408 Embedded documents can now be soft deleted via `Mongoid::Paranoia`.

## 2.3.0

### New Features

* Mongoid now supports basic localized fields, storing them under the covers as a
  hash of locale => value pairs. `field :name, localize: true`

* \#1275 For applications that default safe mode to true, you can now tell a
  single operation to persist without safe mode via #unsafely:
  `person.unsafely.save`, `Person.unsafely.create`. (Matt Sanders)

* \#1256 Mongoid now can create indexes for models in Rails engines. (Caio Filipini)

* \#1228 Allow pre formatting of compsoite keys by passing a block to #key.
  (Ben Hundley)

* \#1222 Scoped mass assignment is now supported. (Andrew Shaydurov)

* \#1196 Timestamps can now be turned off on a call-by-call basis via the use
  of #timeless: `person.timeless.save`, `Person.timeless.create(:title => "Sir")`.

* \#1103 Allow developers to create their own custom complex criteria. (Ryan Ong)

* Mongoid now includes all defined fields in `serializable_hash` and `to_json`
  results even if the fields have no values to make serialized documents easier
  to use by ActiveResource clients.

* Support for MongoDB's $and operator is now available in the form of:
  `Criteria#all_of(*args)` where args is multiple hash expressions.

* \#1250, \#1058 Embedded documents now can have their callbacks fired on a parent
  save by setting `:cascade_callbacks => true` on the relation.
  (pyromanic, Paul Rosania, Jak Charlton)

### Major Changes

* Mongoid now depends on Active Model 3.1 and higher.

* Mongoid now depends on the Mongo Ruby Driver 1.4 and higher.

* Mongoid requires MongoDB 2.0.0 and higher.

### Resolved Issues

* \#1308 Fixed scoping of HABTM finds.

* \#1300 Namespaced models should handle recursive embedding properly.

* \#1299 Self referenced documents with versioning no longer fail when inverse_of
  is not defined on all relations.

* \#1296 Renamed internal building method to _building.

* \#1288, \#1289 _id and updated_at should not be part of versioned attributes.

* \#1273 Mongoid.preload_models now checks if preload configuration option is set,
  where Mongoid.load_models always loads everything. (Ryan McGeary)

* \#1244 Has one relations now adhere to default dependant behaviour.

* \#1225 Fixed delayed persistence of embedded documents via $set.

* \#1166 Don't load config in Railtie if no env variables defined. (Terence Lee)

* \#1052 `alias_attribute` now works again as expected.

* \#939 Apply default attributes when upcasting via #becomes. (Christos Pappas)

* \#932 Fixed casting of integer fields with leading zeros.

* \#948 Reset version number on clone if versions existed.

* \#763 Don't merge $in criteria arrays when chaining named scopes.

* \#730 Existing models that have relations added post persistence of originals
  can now have new relations added with no migrations.

* \#726 Embedded documents with compound keys not validate uniqueness correctly.

* \#582 Cyclic non embedded relations now validate uniqueness correctly.

* \#484 Validates uniqueness with multiple scopes of all types now work properly.

* Deleting versions created with `Mongoid::Versioning` no longer fires off
  dependent cascading on relations.

## 2.2.4

* \#1377 Fix aggregation functions to properly handle nil or indefined values.
  (Maxime Garcia)

* \#1373 Warn if a scope overrides another scope.

* \#1372 Never persist when binding inside of a read attribute for validation.

* \#1358 Fixed type error on many to many synchronization when inverse_of is
  set to nil.

* \#1356 $in criteria can now be chained to non-complex criteria on the same
  key without error.

* \#1350, \#1351 Fixed errors in the string conversions of double quotes and
  tilde when paramterizing keys.

* \#1349 Mongoid documents should not blow up when including Enumerable.
  (Jonas Nicklas)

## 2.2.3

* \#1295 Fixed having multiple includes only execute the eager loading of the first.

* \#1225 Fixed delayed persistence of embedded documents via $set.

* \#1002 Fix BSON object id conversion to check if legal first.

## 2.2.2

* This release removes the restriction of a dependency on 1.3.x of the mongo
  ruby driver. Users may now use 1.3.x through 1.4.x.

## 2.2.1

### Resolved Issues

* \#1210, \#517 Allow embedded document relation queries to use dot notation.
  (Scott Ellard)

* \#1198 Enumerable target should use criteria count if loaded has no docs.

* \#1164 Get rid of remaining no method in_memory errors.

* \#1070 Allow custom field serializers to have their own constructors.

* \#1176 Allow access to parent documents from embedded docs in after_destroy
  callbacks.

* \#1191 Context group methods (min, max, sum) no longer return NaN but instead
  return nil if field doesn't exist or have values.

* \#1193, \#1271 Always return Integers for integer fields with .000 precisions,
  not floats.

* \#1199 Fixed performance issues of hash and array field access when reading
  multiple times.

* \#1218 Fixed issues with relations referencing models with integer foreign keys.

* \#1219 Fixed various conflicting modifications issues when pushing and pulling
  from the same embedded document in a single call.

* \#1220 Metadata should not get overwritten by nil on binding.

* \#1231 Renamed Mongoid's atomic set class to Sets to avoid conflicts with Ruby's
  native Set after document inclusion.

* \#1232 Fix access to related models during before_destroy callbacks when
  cascading.

* \#1234 Fixed HABTM foreign key synchronization issues when destroying
  documents.

* \#1243 Polymorphic relations dont convert to object ids when querying if the
  ids are defined as strings.

* \#1247 Force Model.first to sort by ascending id to guarantee first document.

* \#1248 Added #unscoped to embedded many relations.

* \#1249 Destroy flags in nested attributes now actually destroy the document
  for has_many instead of just breaking the relation.

* \#1272 Don't modify configuration options in place when creating replica set
  connections.

## 2.2.0

### New Features

* Mongoid now contains eager loading in the form of `Criteria#includes(*args)`.
  This works on has_one, has_many, belongs_to associations and requires the identity map to
  be enabled in order to function. Set `identity_map_enabled: true` in your
  `mongoid.yml`. Ex: `Person.where(title: "Sir").includes(:posts, :game)`

* Relations can now take a module as a value to the `:extend` option. (Roman
  Shterenzon)

* Capped collections can be created by passing the options to the `#store_in`
  macro: `Person.store_in :people, capped: true, max: 1000000`

* Mongoid::Collection now supports `collection.find_and_modify`

* `Document#has_attribute?` now aliases to `Document#attribute_present?`

* \#930 You can now turn off the Mongoid logger via the mongoid.yml by
doing `logger: false`

* \#909 We now raise a `Mongoid::Errors::Callback` exception if persisting with
a bang method and a callback returns false, instead of the uninformative
validations error from before.

### Major Changes

* \#1173 has_many relations no longer delete all documents on a set of the relation
 (= [ doc_one, doc_two ]) but look to the dependent option to determine what
 behaviour should occur. :delete and :destroy will behave as before, :nullify and
 no option specified will both nullify the old documents without deleting.

* \#1142, \#767 Embedded relations no longer immediately persist atomically
when accessed via a parent attributes set. This includes nested attributes setting
and `attributes=` or `write_attributes`. The child changes then remain dirty and
atomically update when save is called on them or the parent document.

### Resolved Issues

* \#1190 Fixed the gemspec errors due to changing README and CHANGELOG to markdown.

* \#1180, \#1084, \#955 Mongoid now checks the field types rather than if the name
contains `/id/` when trying to convert to object ids on criteria.

* \#1176 Enumerable targets should always return the in memory documents first,
when calling `#first`

* \#1175 Make sure both sides of many to many relations are in sync during a create.

* \#1172 Referenced enumerable relations now properly handle `#to_json`
(Daniel Doubrovkine)

* \#1040 Increased performance of class load times by removing all delegate calls
to self.class.

## 2.1.9

### Resolved Issues

* \#1159 Fixed build blocks not to cancel out each other when nested.

* \#1154 Don't delete many-to-many documents on empty array set.

* \#1153 Retain parent document reference in after callbacks.

* \#1151 Fix associated validation infinite loop on self referencing documents.

* \#1150 Validates associated on `belongs_to` is `false` by default.

* \#1149 Fixed metadata setting on `belongs_to` relations.

* \#1145 Metadata inverse should return `nil` if `inverse_of` was set as `nil`.

* \#1139 Enumerable targets now quack like arrays.

* \#1136 Setting `belongs_to` parent to `nil` no longer deletes the parent.

* \#1120 Don't call `in_memory` on relations if they don't respond to it.

* \#1075 Set `self` in default procs to the document instance.

* \#1072 Writing attributes for nested documents can take a hash or array of hashes.

* \#990 Embedded documents can use a single `embedded_in` with multiple parent definitions.

## 2.1.8

### Resolved Issues

* \#1148 Fixed `respond_to?` on all relations to return properly.

* \#1146 Added back the Mongoid destructive fields check when defining fields.

* \#1141 Fixed conversions of `nil` values in criteria.

* \#1131 Verified Mongoid/Kaminari paginating correctly.

* \#1105 Fixed atomic update consumer to be scoped to class.

* \#1075 `self` in default lambdas and procs now references the document instance.

* \#740 Removed `embedded_object_id` configuration parameter.

* \#661 Fixed metadata caching on embedded documents.

* \#595 Fixed relation reload flagging.

* \#410 Moving documents from one relation to another now works as expected.

## 2.1.7

This was a specific release to fix MRI 1.8.7 breakages introduced by 2.1.6.

## 2.1.6

### Resolved Issues

* \#1126 Fix setting of relations with other relation proxies.

* \#1122 Hash and array fields now properly flag as dirty on access and change.

* \#656 Fixed reload breaking relations on unsetting of already loaded associations.

* \#647 Prefer `#unset` to `#remove_attribute` for removing values.

* \#290 Verify pushes into deeply embedded documents.

## 2.1.5

### Resolved Issues

* \#1116 Embedded children retain reference to parent in destroy callbacks.

* \#1110, \#1115 Don't memoize metadata related helpers on documents.

* \#1112 `db:create_indexes` no longer indexes subclasses multiple times.

* \#1111, \#1098 Don't set `_id` in `$set` operations.

* \#1007 Update attribute properly tracks array changes.

## 2.1.4

This was a specific release to get a Psych generated gemspec so no more parse errors would occur on those rubies that were using the new YAML parser.

## 2.1.3

### Resolved Issues

* \#1109 Fixed validations not loading one to ones into memory.

* \#1107 Mongoid no longer wants required `mongoid/railtie` in `application.rb`.

* \#1102 Fixed nested attributes deletion.

* \#1097 Reload now runs `after_initialize` callbacks.

* \#1079 Embeds many no longer duplicates documents.

* \#1078 Fixed array criteria matching on embedded documents.

* \#1028 Implement scoped on one-to-many and many-to-many relations.

* \#988 Many-to-many clear no longer deletes the child documents.

* \#977 Autosaving relations works also through nested attributes.

* \#972 Recursive embedding now handles namespacing on generated names.

* \#943 Don't override `Document#attributes`.

* \#893 Verify count is not caching on many to many relations.

* \#815 Verify `after_initialize` is run in the correct place.

* \#793 Verify `any_of` scopes chain properly with any other scope.

* \#776 Fixed mongoid case quality when dealing with subclasses.

* \#747 Fixed complex criteria using its keys to render its string value.

* \#721 `#safely` now properly raises validation errors when they occur.

## 2.1.2

### Resolved Issues

* \#1082 Alias `size` and `length` to `count` on criteria. (Adam Greene)

* \#1044 When multiple relations are defined for the same class, always return the default inverse first if `inverse_of` is not defined.

* \#710 Nested attributes accept both `id` and `_id` in hashes or arrays.

* \#1047 Ignore `nil` values passed to `embeds_man` pushes and substitution. (Derick Bailey)

## 2.1.1

### Resolved Issues

* \#1021, \#719 Many to many relations dont trigger extra database queries when pushing new documents.

* \#607 Calling `create` on large associations does not load the entire relation.

* \#1064 `Mongoid::Paranoia` should respect `unscoped` and `scoped`.

* \#1026 `model#update_attribute` now can update booleans to `false`.

* \#618 Crack XML library breaks Mongoid by adding `#attributes` method to the `String` class. (Stephen McGinty)

## 2.1.0

### Major Changes

* Mongoid now requires MongoDB 1.8.x in order to properly support the `#bit` and `#rename` atomic operations.

* Traditional slave support has been removed from Mongoid. Replica sets should be used in place of traditional master and slave setups.

* Custom field serialization has changed. Please see [serializable](https://github.com/mongoid/mongoid/blob/master/lib/mongoid/fields/serializable.rb) for changes.

* The dirty attribute tracking has been switched to use ActiveModel, this brings many bug fixes and changes:

  * \#756 After callbacks and observers see what was changed instead of changes just made being in previous_changes

  * \#434 Documents now are flagged as dirty when brand new or the state on instantiation differs from the database state. This is consistent with ActiveRecord.

  * \#323 Mongoid now supports [field]_will_change! from ActiveModel::Dirty

* Mongoid model preloading in development mode now defaults to `false`.

* `:autosave => true` on relational associations now saves on update as well as create.

* Mongoid now has an identity map for simple `find_by_id` queries. See the website for documentation.

### New Features

* \#1067 Fields now accept a `:versioned` attribute to be able to disable what fields are versioned with `Mongoid::Versioning`. (Jim Benton)

* \#587 Added order preference to many and many to many associations. (Gregory Man)

* Added ability to chain `order_by` statements. (Gregory Man)

* \#961 Allow arbitrary `Mongo::Connection` options to pass through `Mongoid::Config::Database` object. (Morgan Nelson)

* Enable `autosave` for many to many references. (Dave Krupinski)

* The following explicit atomic operations have been added: `Model#bit`, `Model#pop`, `Model#pull`, `Model#push_all`, `Model#rename`, `Model#unset`.

* Added exception translations for Hindi. (Sukeerthi Adiga)

### Resolved Issues

* \#974 Fix `attribute_present?` to work correctly then attribute value is `false`, thanks to @nickhoffman. (Gregory Man)

* \#960 create indexes rake task is not recognizing a lot of mongoid models because it has problems guessing their model names from filenames. (Tobias Schlottke)

* \#874 Deleting from a M-M reference is one-sided. (nickhoffman, davekrupinski)

* Replace deprecated `class_inheritable_hash` dropped in Rails 3.1+. (Konstantin Shabanov)

* Fix inconsistent state when replacing an entire many to many relation.

* Don't clobber inheritable attributes when adding subclass field inheritance. (Dave Krupinski)

* \#914 Querying embedded documents with `$or` selector. (Max Golovnia)

* \#514 Fix marshaling of documents with relation extensions. (Chris Griego)

* `Metadata#extension` now returns a `Module`, instead of a `Proc`, when an extension is defined.

* \#837 When `allow_dynamic_fields` is set to `false` and loading an embedded document with an unrecognized field, an exception is raised.

* \#963 Initializing array of embedded documents via hash regressed (Chris Griego, Morgan Nelson)

* `Mongoid::Config.reset` resets the options to their default values.

* `Mongoid::Fields.defaults` is memoized for faster instantiation of models.
