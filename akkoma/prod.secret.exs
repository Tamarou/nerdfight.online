import Config

config :pleroma, Pleroma.Web.Endpoint,
  url: [host: System.get_env("DOMAIN")]

config :pleroma, Pleroma.Web.WebFinger, domain: System.get_env("STATIC_DOMAIN")

config :joken, default_signer: System.get_env("JWT_SIGNER")

config :pleroma, Pleroma.Upload, base_url: System.get_env("MEDIA_URL")

config :pleroma, Pleroma.Repo,
  port: 25060,
  ssl: true,
  prepare: :named,
  parameters: [
    plan_cache_mode: "force_custom_plan"
  ]

config :pleroma, configurable_from_database: true
