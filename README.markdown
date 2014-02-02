# Multidb

A simple, no-nonsense ActiveRecord extension which allows the application to switch between multiple database connections, such as in a master/slave environment. For example:

    Multidb.use(:slave) do
      @posts = Post.all
    end

The extension was developed in order to support PostgreSQL 9.0's new hot standby support in a production environment.

Randomized balancing of multiple connections within a group is supported. In the future, some kind of automatic balancing of read/write queries could be implemented.

## Requirements

* Ruby 1.9.3 or later.
* ActiveRecord 3.0 or later. (Earlier versions can use the gem version 0.1.10.)

## Comparison to other ActiveRecord extensions

Compared to other, more full-featured extensions such as Octopus and Seamless Database Pool:

**Minimal amount of monkeypatching magic**. The only part of ActiveRecord that is overridden is `ActiveRecord::Base#connection`.

**Non-invasive**. Very small amounts of configuration and changes to the client application are required.

**Orthogonal**. Unlike Octopus, for example, connections follow context:

    Multidb.use(:master) do
      @post = Post.find(1)
      Multidb.use(:slave) do
        @post.authors  # This will use the slave
      end
    end

**Low-overhead**. Since `connection` is called on every single database operation, it needs to be fast. Which it is: Multidb's implementation of
`connection` incurs only a single hash lookup in `Thread.current`.

However, Multidb also has fewer features. At the moment it will _not_ automatically split reads and writes between database backends.

## Getting started

Add to your `Gemfile`:

    gem 'ar-multidb', :require => 'multidb'

All that is needed is to set up your `database.yml` file:

    production:
      adapter: postgresql
      database: myapp_production
      username: ohoh
      password: mymy
      host: db1
      multidb:
        databases:
          slave:
            host: db-slave

Each database entry may be a hash or an array. So this also works:

    production:
      adapter: postgresql
      database: myapp_production
      username: ohoh
      password: mymy
      host: db1
      multidb:
        databases:
          slave:
            - host: db-slave1
            - host: db-slave2

If multiple elements are specified, Multidb will use the list to pick a random candidate connection.

The database hashes follow the same format as the top-level adapter configuration. In other words, each database connection may override the adapter, database name, username and so on.

To use the connection, modify your code by wrapping database access logic in blocks:

    Multidb.use(:slave) do
      @posts = Post.all
    end

To wrap entire controller requests, for example:

    class PostsController < ApplicationController
      around_filter :run_using_slave, only: [:index]

      def index
        @posts = Post.all
      end

      def edit
        # Won't be wrapped
      end

      def run_using_slave(&block)
        Multidb.use(:slave, &block)
      end
    end

You can also set the current connection for the remainder of the thread's execution:

    Multidb.use(:slave)
    # Do work
    Multidb.use(:master)

Note that the symbol `:default` will (unless you override it) refer to the default top-level ActiveRecord configuration.

## Development mode

In development you will typically want `Multidb.use(:slave)` to still work, but you probably don't want to run multiple databases on your development box. To make `use` silently fall back to using the default connection, Multidb can run in fallback mode.

If you are using Rails, this will be automatically enabled in `development` and `test` environments. Otherwise, simply set `fallback: true` in `database.yml`:

    development:
      adapter: postgresql
      database: myapp_development
      username: ohoh
      password: mymy
      host: db1
      multidb:
        fallback: true

## Limitations

Multidb does not support per-class connections (eg., calling `establish_connection` within a class, as opposed to `ActiveRecord::Base`).

## Legal

Copyright (c) 2011-2014 Alexander Staubo. Released under the MIT license. See the file `LICENSE`.
