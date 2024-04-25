--!optimize 2
--!strict
--!native

--- eXtended sTRUCT by jiwonz

local MsgPack = require(script.Parent["msgpack-luau"])
local CRC16 = require(script.Parent.crc16)

local none = function()end
local strictMode = true
local useHashing = true

local module = {}

local function cloneTableDeep(original:{[any]:any}):{[any]:any}
	local copy = {}
	for k,v in original do
		if type(v) == "table" then
			v = cloneTableDeep(v)
		end
		copy[k] = v
	end
	return copy
end

local function mapTableDeep(t:{[any]:any},map:{[any]:any}?)
	for k,v in t do
		if type(v) == "table" then
			mapTableDeep(v)
		else
			if map then
				local new = map[k]
				if new then
					t[k] = nil
					k = new
				end
			end
			t[k] = v
		end
	end
end

local function inverseTableKeys(t:{[any]:any}):{[any]:any}
	local new = {}
	for k,v in t do
		new[v] = k
	end
	return new
end

local function deepCopyStruct<T>(original:T):T
	if type(original) ~= "table" then
		error("this must be a table")
	end
	local copy = {}
	for k, v in original do
		if v == none then
			continue
		end
		if type(v) == "table" then
			v = deepCopyStruct(v)
		end
		copy[k] = v
	end
	return copy::any
end

local function checkInvalid(struct,props)
	for k,v in props do
		if struct[k] == nil then
			local validFields = {}
			for field,_ in struct do
				table.insert(validFields,"'"..field.."'")
			end
			error(`This struct (which has {table.concat(validFields,", ")} fields) has no field named '{k}'`)
		end
	end
end

export type XtructInstant<T> = T
export type XtructImpl<T={[string]:any}> = {
	Struct:T;
	HashMap:{};
	__index:XtructImpl<T>;
	Pack:(self:XtructImpl<T>,instant:XtructInstant<T>)->(string);
	Unpack:(self:XtructImpl<T>,packedInstant:string)->(XtructInstant<T>);
	With:(self:XtructImpl<T>,f:(clone:T)->())->(XtructInstant<T>);
	__call:(self:XtructImpl<T>,fields:T)->(XtructInstant<T>);
}
export type Xtruct<T> = typeof(setmetatable({}::{Struct:T},{}::XtructImpl<T>))&(fields:T)->(XtructInstant<T>)
local Xtruct = {}::XtructImpl
Xtruct.__index = Xtruct

function Xtruct:Pack<T>(instant:XtructInstant<T>):string
	if type(instant) ~= "table" then
		error(`table expected, got {typeof(instant)}`)
	end
	if useHashing then
		local hashMap = if useHashing == true then self.HashMap else nil
		if not hashMap then
			local struct = self.Struct
			local map = {}
			for k,v in struct do
				map[k] = CRC16(k)
			end
			hashMap = map
			self.HashMap = map
		end
		instant = cloneTableDeep(instant)::any
		mapTableDeep(instant,hashMap)
	end
	return MsgPack.encode(instant)
end

function Xtruct:Unpack(packedInstance:string):{[string]:any}
	local unpackedInstance = MsgPack.decode(packedInstance)
	if useHashing then
		local hashMap:any = if useHashing == true then self.HashMap else nil
		if not hashMap then
			local struct = self.Struct
			local map = {}
			for k,v in struct do
				map[k] = CRC16(k)
			end
			hashMap = map
			self.HashMap = map
		end
		mapTableDeep(unpackedInstance,inverseTableKeys(hashMap))
	end
	return unpackedInstance
end

function Xtruct:With(f:any):any
	local struct = self.Struct
	local new = deepCopyStruct(struct)
	f(new)
	if strictMode then
		checkInvalid(struct,new)
	end
	return new
end

function Xtruct:__call<T>(fields:T):T
	if type(fields) == "table" then
		local struct = self.Struct
		if strictMode then
			checkInvalid(struct,fields)
		end

		for k, v in struct do
			if fields[k] ~= nil then
				continue
			end
			if v == none then
				continue
			end
			if type(v) == "table" then
				v = deepCopyStruct(v)
			end
			fields[k] = v
		end

		return fields
	else
		error(`table expected, got {type(fields)}`)
	end
end

function module.new<T>(struct:T):Xtruct<T>
	if type(struct) ~= "table" then
		error(`Table expected, got {type(struct)}`)
	end
	return setmetatable({Struct=struct},Xtruct)::Xtruct<T>
end

function module.setStrictMode(enable:boolean)
	assert(type(enable)=="boolean","Must be a boolean")
	strictMode = enable
end

function module.setUseHashing(enable:boolean)
	assert(type(enable)=="boolean","Must be a boolean")
	useHashing = enable
end

module.string = (none::any)::string
module.boolean = (none::any)::boolean
module.table = (none::any)::{}
module.number = (none::any)::number
module.stringOptional = (none::any)::string?
module.booleanOptional = (none::any)::boolean?
module.tableOptional = (none::any)::{}?
module.numberOptional = (none::any)::number?

return module
