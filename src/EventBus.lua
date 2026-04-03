-- EventBus.lua
-- Centralized publish/subscribe event system for decoupled module communication
-- v2.5 | roblox-procedural-worlds

local EventBus = {}
EventBus.__index = EventBus

local subscribers = {}

-- Subscribe to an event
-- @param eventName string
-- @param callback function
-- @returns unsubscribe function
function EventBus.on(eventName, callback)
	assert(type(eventName) == "string", "eventName must be a string")
	assert(type(callback) == "function", "callback must be a function")

	if not subscribers[eventName] then
		subscribers[eventName] = {}
	end

	local id = #subscribers[eventName] + 1
	subscribers[eventName][id] = callback

	return function()
		subscribers[eventName][id] = nil
	end
end

-- Subscribe to an event once
function EventBus.once(eventName, callback)
	local unsub
	unsub = EventBus.on(eventName, function(...)
		callback(...)
		unsub()
	end)
	return unsub
end

-- Emit an event with optional payload
function EventBus.emit(eventName, ...)
	assert(type(eventName) == "string", "eventName must be a string")

	if not subscribers[eventName] then return end

	for _, callback in pairs(subscribers[eventName]) do
		task.spawn(callback, ...)
	end
end

-- Clear all subscribers for an event
function EventBus.clear(eventName)
	if eventName then
		subscribers[eventName] = nil
	else
		subscribers = {}
	end
end

-- List active event channels (debug)
function EventBus.debug()
	local result = {}
	for name, subs in pairs(subscribers) do
		local count = 0
		for _ in pairs(subs) do count += 1 end
		table.insert(result, name .. ": " .. count .. " subscriber(s)")
	end
	return table.concat(result, "\n")
end

return EventBus
