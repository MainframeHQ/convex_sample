# SampleDirectory

Simple directory service

All the data is stored in a named ETS table and will be lost after a restart.

This application showcases:
  - operations handled in the calling process.
  - basic access right managment.

Provides operations:

  - `directory.add`:

    Arguments:
      - `id` (`String.t`)
      - `name` (`String.t`)
      - `nick` (`String.t`)

    Returns the created profile as a map.

  - `directory.lookup`:

    Arguments:
      - `id` (`String.t`)

    Returns the profile as a map.
