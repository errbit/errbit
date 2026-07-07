See [AGENTS.md](AGENTS.md) for project conventions, the Mongo→SQL port plan, and commands.

## Spec conventions

- In RSpec, every `context` block description **must** start with `when`, `with`, or `without`. Examples: `context "when user is an admin"`, `context "with valid params"`, `context "without a tracker configured"`. Do not start a context with `as`, `for`, a participle, or any other word.

## Ruby block style

- Use `{ ... }` only for **single-line** blocks. For any block that spans more than one line, use `do ... end`. This applies everywhere — including `expect { ... }.to …`, `lambda { ... }`, `Proc.new { ... }`, `Hash#each { ... }`, `before { ... }`, etc. A multi-line `expect` becomes `expect do … end.to …`.
