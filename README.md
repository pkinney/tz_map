# TzMap

`TzMap` provides a mapping of spatial coordinates to time zone names.

Given a longitude and latitude, the name of the time zone at that corresponds to that location.
This is derived from the [tz_world](http://efele.net/maps/tz/world/) project.

```elixir
iex> TzMap.for_location(-90.081074, 29.951075)
"America/Chicago"
```

## Limitations

* Does not yet support time zones at sea.

## Installation

The package can be installed
by adding `tz_map` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tz_map, "~> 0.1.0"}
  ]
end
```
