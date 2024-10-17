--!optimize 2
--!native
--!strict

local json = require(script.Parent["luau-json"])
local base64 = require(script.Parent.base64)

local HttpService = game:GetService("HttpService")

local function compress(buf: buffer): string? --// WARNING: if the compression ratio is 0, it returns nil
	local j = HttpService:JSONEncode(buf)
	local t = json.decode(j) :: { zbase64: string }
	local zb64 = t.zbase64
	if not zb64 then
		return nil
	end
	local compressed = base64.decode(buffer.fromstring(zb64))
	return compressed
end

local function decompress(compressed: string): buffer
	local zb64 = base64.encode(buffer.fromstring(compressed))
	local j = ("{\"m\":null,\"t\":\"buffer\",\"zbase64\":\"%s\"}"):format(buffer.tostring(zb64))
	local buf = HttpService:JSONDecode(j)
	return buf
end

return {
	compress = compress,
	decompress = decompress
}
