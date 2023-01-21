import Mix.Config

config :pleroma, Pleroma.Web.Endpoint,
  url: [host: System.get_env("DOMAIN")]

config :pleroma, Pleroma.Web.WebFinger, domain: System.get_env("STATIC_DOMAIN")

config :joken, default_signer: System.get_env("JWT_SIGNER")

config :pleroma, configurable_from_database: true
