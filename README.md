[![Build Status](https://travis-ci.org/WGBH/hydradam2.svg?branch=iu-demo)](https://travis-ci.org/WGBH/hydradam2)

# HydraDAM

A Hydra app that focuses on Digital Asset Management functions.


## Dependencies

HydraDAM has the following dependencies that you must install yourself.

1. Ruby >= 2.2.0
1. Java 1.8
1. Redis server

## Development Setup

> NOTE: All commands after Step 1 should be run from where ever your code is located.

1. Clone the repository
  ```bash
  cd path/to/wherever/you/want/your/code/to/live
  git clone https://github.com/WGBH/hydradam2.git
  ```

1. Download a clean copy of [hydra-jetty](https://github.com/projecthydra/hydra-jetty).
  ```bash
  rake jetty:clean
  ```

1. Copy HydraDAM's Solr and Fedora config over to your new copy of hydra-jetty.
  ```bash
  rake jetty:config
  ```

1. Start jetty. You will be returned to your command prompt when it has
   finished starting up.
  ```bash
  rake jetty:start
  ```

1. Verify jetty is running by visiting http://127.0.0.1:8983. You should see a
   very basic page with the Hydra logo, and links to Fedora and Solr.

   > NOTE: you must wait for jetty to have finished starting up (see previous
   > step).

1. Install gems
  ```bash
  bundle install
  ```

1. Migrate the database
  ```bash
  rake db:migrate
  ```

1. Start Redis server from a separate terminal window.
   ```bash
   # From a dedicated terminal window...
   redis-server
   ```

   > NOTE: By default, closing the window will stop Redis. If you don't want
   > to keep a dedicated terminal window open, then you can use `&` to
   > background the process, e.g.
     ```bash
     # This will background the process so you can continue to use the
     # terminal window, and redirect all output to a file named "redis.log"
     # that you can view.
     redis-server 2>&1 > redis.log &
     ```

1. Start Resque workers
  ```bash
  QUEUE=* rake resque:work
  ```

1. Start Rails from a separate terminal window.
  ```bash
  rake rails s
  ```

1. Verify Rails is working by opening http://localhost:3000 in your browser.