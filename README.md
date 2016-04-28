# KitCat

*Sometimes schema migrations are just not enough.*

Data migration framework written in plain Ruby. It is pretty generic, since it does not depend on any web framework.

## Features of Framework

This is a small migration framework that offers the following functionality for free:

1. Logging
2. Progress Bar
3. Gracefully handling when user interrupts (Ctrl+C or `kill <process_id>`)

## Example Usage

Assuming that the migration strategy is implemented with a class `MigrationStrategy`, then executing a migration is quite simple:

``` ruby
migration_strategy  = MigrationStrategy.new
migration_framework = Migrations::Framework.new(migration_strategy)
migration_framework.execute
```

The above will run the migration and will create a log file inside the `log` directory (which is created if not present)

[How to implement MigrationStrategy](./docs/STRATEGY.md)

# Testing

```bash
  bundle exec rake
```
