# SampleAuth

Simple authentication service.

All the credentials are stored in process memory and will be lost after a restart.

This application showcases:
  - operations delegated to a process.
  - context authentication and policy.


Provides operations:

  - `auth.register`:

    Arguments:
      - `username` (`String.t`)
      - `password` (`String.t`)

    Returns the `user_id` (String.t)

  - `auth.login`:

    Arguments:
      - `username` (`String.t`)
      - `password` (`String.t`)

    Returns the `user_id` (String.t)
