Geocoder.configure(
  lookup: :mapbox,
  api_key: ENV["MAPBOX_ACCESS_TOKEN"],
  units: :km,
  timeout: 5,
  use_https: true
)