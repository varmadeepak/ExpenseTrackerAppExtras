local typedefs = require "kong.db.schema.typedefs"

return {
  name = "custom-auth",
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { auth_service_url = { type = "string", required = true, default = "http://127.0.0.1:8005/auth/v1/ping" } },
        },
      },
    },
  },
}