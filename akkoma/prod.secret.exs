import Config

config :pleroma, Pleroma.Web.Endpoint,
  url: [host: System.get_env("DOMAIN")]

config :pleroma, Pleroma.Web.WebFinger, domain: System.get_env("STATIC_DOMAIN")

config :joken, default_signer: System.get_env("JWT_SIGNER")

config :pleroma, Pleroma.Repo,
  prepare: :named,
  parameters: [
    plan_cache_mode: "force_custom_plan"
  ]

config :pleroma, configurable_from_database: true
