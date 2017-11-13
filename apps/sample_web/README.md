# SampleWeb

## Build

To start your Phoenix server:

* Install dependencies with `mix deps.get`
* Install Node.js dependencies with `cd assets && npm install`
* Start Phoenix endpoint with `mix phx.server`


## Web API

Visit [`localhost:4000`](http://localhost:4000) from your browser.


## Websocket Command API

Demonstrates how to use Convex for an asynchronous stateful API.

It implements a text-based API to interact with the services.

Connect with `wscat --connect http://localhost:4000/api/ws`.

e.g.

```
$ wscat --connect http://localhost:4000/api.ws
> \register foo secret Foo fu
< ##AUTHENTICATED##
> \join test
< ##ROOM JOINED##
< History:
> \post hello
< ##POSTED##
> \leave
< ##LEFT##
```

You can connect and register/login with different users to test notifications.
