--!optimize 2
--!strict
--!native

-- credit goes to https://github.com/battlemesh/battlemesh-packages/blob/master/packages/wbm-testbed/files/usr/lib/lua/crc16.lua
-- licensed in GNU v3 due to source (same license)

return function(str)
    local crc

    local function initCrc()
        crc = 0xffff
    end

    local function updCrc(byte)
        crc = bit32.bxor(crc, byte)
        for i=1,8 do
            local j = bit32.band(crc, 1)
            crc = bit32.rshift(crc, 1)
            if j ~= 0 then
                crc = bit32.bxor(crc, 0x8408)
            end
        end
    end

    local function getCrc(str)
        initCrc()
        for i = 1, #str  do
            updCrc(str:byte(i))
        end
        return crc
    end
    return getCrc(str)
end
