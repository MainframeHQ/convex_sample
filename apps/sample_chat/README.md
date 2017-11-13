# SampleChat

Simple chatroom service.

Starts a process for each rooms and keep the data in the room process memory
so restarting the service will lose all the data.

Operations requires an authenticated context.

This application showcases:
  - basic access right management.
  - proxy binding to notify another service.
  - operation producing multiple results.
  - operations spawning processes if required.

Provides operations:

  - `chat.join`:

    Arguments:
      - `name` (`String.t`)

    Returns the `room_id` (String.t)

  - `chat.produce.history`:

    Arguments:
      - `room_id` (`String.t`)
      - `size` (`integer`)
      - `bind` (optional `boolean`)

    Produce the last `size` messages as `{index :: integer, timestamp: integer, user_id :: String.t, message: String.t}`

  - `chat.leave`:

    Arguments:
      - `room_id` (`String.t`)

    Returns `nil`.

  - `chat.produce.participants`:

    Arguments:
      - `room_id` (`String.t`)

    Produces the `user_id` of all participants.

  - `chat.post`:

    Arguments:
      - `room_id` (`String.t`)
      - `message` (`String.t`)

    Returns `nil`.
