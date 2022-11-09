defmodule TzMap do
  @moduledoc """
  `TzMap` provides a mapping of spatial coordinates to time zone names.

  Given a longitude and latitude, the name of the time zone at that corresponds to that location.
  This is derived from the (tz_world)[http://efele.net/maps/tz/world/] project.

  ## Limitations

  * Does not yet support time zones at sea.

  """

  @doc """
  Returns the time zone name for the given location. Returns `nil` if that location does not
  have a time zone (currently, this only occurs if the location is in an ocean).

  ## Examples

      iex> TzMap.for_location(-90.081074, 29.951075)
      "America/Chicago"

      iex> TzMap.for_location(-147, 37)
      nil

  """
  def for_location(longitude, latitude) do
    TzMap.Server.query(longitude, latitude)
  end
end
