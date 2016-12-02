local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "roomsvrhelper"
local base = require "base"

local RoomsvrNotice = {}

function RoomsvrNotice.process(session, source, event, ...)
	local f = RoomsvrNotice[event] 
	if f == nil then
		return
	end
	f(...)
end

function RoomsvrNotice.get_roomsvr_states( ... )
	local server = msghelper:get_server()
	for id, tableinfo in pairs(server.used_table_pool) do
		skynet.send(tableinfo.table_service, "lua", "notice", "get_roomsvr_state")
	end
end

function RoomsvrNotice.recoverydata(table_data )
	filelog.sys_info("RoomsvrNotice.recoverydata")
	local server = msghelper:get_server()
	local tableinfo = server.used_table_pool[table_data.id]
	if tableinfo ~= nil then
		skynet.send(tableinfo.table_service, "lua", "notice", "recoverydata",table_data)
	end
end

return RoomsvrNotice