--[=[
	@class CreateInstance
	This is a module that is used to quickly and neatly create any type of instance and assigned a set of properties to it.
]=]
local CreateInstance = {}

--[=[
	The function will return the instance that was created.
	@param object string | Instance -- The object to create. If this is a string, it will create a new instance of that type. If this is an instance, it will clone that instance.
	@param properties table -- The properties to assign to the instance.
	@return Instance -- The instance that was created.
]=]
function CreateInstance.SetInstanceProperties(object : string | Instance, properties : {})
	if typeof(object) == "string" then
		object = Instance.new(object)
	end
	for name, value in pairs (properties) do
		object[name] = value
	end

	return object
end

return CreateInstance.SetInstanceProperties
