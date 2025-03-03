local kong = kong
local http = require "resty.http"
local cjson = require "cjson.safe"  -- Use cjson.safe for safer JSON parsing

local CustomAuthHandler = {
  PRIORITY = 1000,
  VERSION = "1.0",
}

function CustomAuthHandler:access(config)
  -- Use the auth_service_url from the configuration
  local auth_service_url = config.auth_service_url

  -- Call auth service
  local httpc = http.new()
  httpc:set_timeouts(10000, 10000, 10000)
  local res, err = httpc:request_uri(auth_service_url, {
    method = "GET",
    headers = {
      ["Authorization"] = kong.request.get_header("Authorization")
    }
  })

  if not res then
    kong.log.err("Failed to call auth service: ", err)
    return kong.response.exit(500, { message = "Internal Server Error" })
  end

  if res.status ~= 200 then
    kong.log.err("Auth service returned status: ", res.status)
    return kong.response.exit(res.status, { message = "Unauthorized" })
  end

  -- Check if the response body is valid JSON
  local body, err = cjson.decode(res.body)
  if not body then
    -- If not valid JSON, assume the response body is the user ID
    local user_id = res.body
    if not user_id or #user_id == 0 then
      kong.log.err("Auth service response does not contain user ID")
      return kong.response.exit(500, { message = "Internal Server Error" })
    end
    kong.service.request.set_header("X-USER-ID", user_id)
  else
    -- If valid JSON, extract the user ID
    local user_id = body.userId
    if not user_id then
      kong.log.err("Auth service response does not contain userId")
      return kong.response.exit(500, { message = "Internal Server Error" })
    end
    kong.service.request.set_header("X-USER-ID", user_id)
  end
end

return CustomAuthHandler