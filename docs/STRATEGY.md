# Migration Strategy

## Requirements

However, in order for a migration script to use this framework, it needs to instantiate
a migration strategy, fulfilling the following requirements:

1. Needs to respond to `#criteria`. This should be returning a collection. In fact, an object that responds to `#each`
   and to `#count`. The `#each` called on the result of `#criteria` needs to return a Ruby `Enumerator` or something that
   responds to `#next` giving the next item to be processed.
   So, if we have a `migration_strategy`, then

   1. `criteria.count` needs to be implemented so that its result is the number of items to process in total. Framework needs
       that in order to be able to display a progress bar that would correspond to the actual work load.<br/>
       *Hint:* Think about whether you want the collection `#count` implementation to be counting by eagerly loading
       all the elements of the collection in memory, or, by letting the `#count` be implemented more efficiently. For
       example, if you are querying a database, it might be more appropriate to let the database server do the count for you,
       rather than bringing the whole collection into memory and then counting using Ruby code.<br/>
       **Important:** Just for your information and in order for you to be cautious on the implementation, if one calls `#count`,
       on an `Enumerator` instance, this loads the whole collection into memory before returning the actual result.
   2. `criteria_result = migration_strategy.criteria` needs to be implemented so that `criteria_result` responds
      to `#each`.
   2. `each_result` = `criteria_result.each` needs to be implemented so that `each_result` responds to `#next`
   3. `next_result = each_result#next` is the next item that will be processed. And multiple calls to
      `each_result#next` should bring the next item to be processed, or raise `StopIteration` exception if
      no other item left in the collection.

   The above may seem a little bit complicated, but it is actually easier than what it looks initially. This is because
   the collections in Ruby expose, both a `#count` method and an `#each` method returning an `Enumerator` which supports the `#next`.
   So, for example, if the `#criteria` method returns an `Array`, nothing more is required, because `Array#each`
   returns an `Enumerator` and the `Enumerator#next` returns the next item lazy loaded.

   See later on for two examples migration strategies. One that is using the MongoID interface to access a Mongo DB.
   And another one using the Mongo Ruby Driver for the same database.

1. Needs to respond to `#process(item)`. It should implement a `#process(item)` method that
   will be called by the framework. The method needs to return `true` if the item is processed successfully,
   or `false` if it is not processed successfully. This is taken into account by the framework to keep
   track of the items that have been processed successfully. Also the framework makes sure to log the
   correct lines in the log file accordingly.

1. Optionally, responds to `#interrupt_callback`. This method will not be normally called. It will be called by
   the framework if the user running the migration script interrupts it by hitting the key combination Ctrl+C or by sending
   the signal `SIGTERM (15)` or `SIGINT (2)` (e.g. with `kill process_id` the `SIGTERM` is sent). Hence, the migration strategy
   is responsible to carry out clean up actions for the premature termination of the migration script. It needs to make sure
   that the script finishes gracefully.

## Example Migration Strategies

You can read here two example migration strategies for MongoDB.

### Migration Strategy Using Mongo Ruby Driver

``` ruby
class MigrationStrategy

  def criteria
    query
  end
  
  def process(policy)
    sleep 1
    true
  end

  def interrupt_callback
    puts
    puts "User interrupted...cleaning up"
    puts
  end

  private

  def client
    @client ||= Mongo::Client.new(['127.0.0.1:27017'], database: 'db_development')
  end

  def query
    client[:policies].find
  end
end
```

### Migration Strategy Using MongoID Driver

``` ruby
class MigrationStrategy

  def criteria
     query
  end
  
  def process(policy)
    sleep 1
    true
  end

  def interrupt_callback
    puts
    puts "User interrupted...cleaning up"
    puts
  end

  private

  def query
    Policy.all
  end
end
```

## Logging Details of The Item Processed

The framework logs one line per item processed. Each line, ends with the details of the item processed,
as returned by a call to method `#to_log` on the item. If the item does not respond to `#to_log` the
method `#to_s` is used instead.

The fact that the framework expects the strategy collection items to respond to `#to_log` or `#to_s`, is
quite useful, if the strategy wants to customize what is logged per item inside the log line.

In the following example, the migration strategy is a Mongo Ruby Driver based strategy, whose `#criteria` method
wraps the items of the collection inside a class that responds to `#to_log`. This makes the `#criteria` method
a little bit more complex, because it has to implement the requirements to return something that responds to `#each`.
You can see that it does that, but building an Enumerator collection on top of the existing collection.

``` ruby
class MigrationStrategy
  PolicyItemWrapper = Struct.new(:policy)

  class PolicyItemWrapper
    def to_log
      policy["_id"]
    end
  end

  def criteria
    return enum_for(:criteria) unless block_given?

    enumeration = query.each

    loop do
      yield MigrationStrategy::PolicyItemWrapper.new(enumeration.next)
    end
  end
  
  def process(policy_item_wrapper)
    policy = policy_item_wrapper.policy
    sleep 1
    true
  end

  def interrupt_callback
    puts
    puts "User interrupted ... cleaning up."
    puts
  end

  private

  def client
    @client ||= Mongo::Client.new(['127.0.0.1:27017'], database: 'db_development')
  end

  def query
    client[:policies].find
  end
end
```
