--@realm server
--!strict

if(game:GetService("RunService"):IsClient()) then return {} end

local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")

local module = {}

module.databases = {} :: {[string]: DataStore}
module.databases["joinLogs"] = DataStoreService:GetDataStore("JoinLogs")
module.databases["player"] = DataStoreService:GetDataStore("PlayerData")
module.databases["global"] = DataStoreService:GetDataStore("GlobalData")

module.attempts = 5 :: number

function module.GetData(storeName: string, key: any, default: any): any
	default = default or nil
	
	local store = module.databases[storeName]
	if(not store) then error("Invalid store name '"..storeName.."'.") return end
	
	local data
	for i = 1, module.attempts do
		local success: boolean = pcall(function()
			data = store:GetAsync(key)
			
		end)
		
		if(success) then break
		elseif(i == module.attempts) then return default end

		task.wait(i * 0.1)
		
	end
	
	return data or default
	
end

function module.SetData(storeName: string, key: any, value: any): boolean
	local data
	
	local store = module.databases[storeName]
	if(not store) then error("Invalid store name '"..storeName.."'.") end
	
	for i: number = 1, module.attempts do
		local success: boolean, err: any = pcall(function()
			store:SetAsync(key, value)

		end)
		
		if(success) then return true
		elseif(i == module.attempts) then
			print(err)
			return false
		
		end
		
		task.wait(i * 0.1)

	end

	return false

end

function module.UpdateData(storeName: string, key: any, transform): boolean
	local data

	local store = module.databases[storeName]
	if(not store) then error("Invalid store name '"..storeName.."'.") end
	
	for i: number = 1, module.attempts do
		local success: boolean, err: any = pcall(function()
			store:UpdateAsync(key, transform)

		end)

		if(success) then return true
		elseif(i == module.attempts) then
			print(err)
			return false
		
		end
		
		task.wait(i * 0.1)

	end

	return false

end

function module.RemoveData(storeName: string, key: any): boolean
	local data

	local store = module.databases[storeName]
	if(not store) then error("Invalid store name '"..storeName.."'.") end

	for i: number = 1, module.attempts do
		local success: boolean, err: any = pcall(function()
			store:RemoveAsync(key)

		end)

		if(success) then return true
		elseif(i == module.attempts) then
			print(err)
			return false
		
		end
		
		task.wait(i * 0.1)

	end

	return false

end

function module.GetProductInfo(id, infoType): any
	for i = 1, module.attempts do
		local success, info = pcall(function()
			return MarketplaceService:GetProductInfo(id, infoType)

		end)

		if(success and info) then return info
		elseif(i == module.attempts) then
			print(info)
			return false
		
		end

		task.wait(i * 0.1)

	end

	return false

end

return module
