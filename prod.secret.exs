import Mix.Config

config :pleroma, Pleroma.Web.Endpoint,
  url: [host: "akkoma.nerdfight.online"]

config :pleroma, Pleroma.Web.WebFinger, domain: "nerdfight.online"

config :pleroma, configurable_from_database: true