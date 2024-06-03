--!optimize 2
--!native

local JSON = require(script.json)

local HttpService = game:GetService("HttpService")

--// base64 credits to (https://devforum.roblox.com/t/base64-encoding-and-decoding-in-lua/1719860)
local function fromBase64(data)
	local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
	data = string.gsub(data, '[^'..b..'=]', '')
	return (data:gsub('.', function(x)
		if (x == '=') then return '' end
		local r,f='',(b:find(x)-1)
		for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
		return r;
	end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
		if (#x ~= 8) then return '' end
		local c=0
		for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
		return string.char(c)
	end))
end

local function toBase64(data)
	local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
	return ((data:gsub('.', function(x)
		local r,b='',x:byte()
		for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
		return r;
	end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
		if (#x < 6) then return '' end
		local c=0
		for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
		return b:sub(c+1,c+1)
	end)..({ '', '==', '=' })[#data%3+1])
end

local function compress(buf: buffer): string? --// WARNING: if the compression ratio is 0, it returns nil
	local j = HttpService:JSONEncode(buf)
	local t = JSON.decode(j)
	local zb64 = t.zbase64
	if not zb64 then
		return nil
	end
	local compressed = fromBase64(zb64)
	return compressed
end

local function decompress(compressed: string): buffer
	local zb64 = toBase64(compressed)
	local j = ("{\"m\":null,\"t\":\"buffer\",\"zbase64\":\"%s\"}"):format(zb64)
	local buf = HttpService:JSONDecode(j)
	return buf
end

return {
	compress = compress,
	decompress = decompress
}
