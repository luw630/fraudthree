local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "tablehelper"
local msgproxy = require "msgproxy"
local base = require "base"
local logicmng = require "logicmng"
local filename = "tablecmd.lua"
local tabletool = require "tabletool"
require "enum"
local TableCMD = {}

function TableCMD.process(session, source, event, ...)
	local f = TableCMD[event] 
	if f == nil then
		filelog.sys_error(filename.." TableCMD.process invalid event:"..event)
		return nil
	end
	f(...)	 
end
--[[
conf = {
	....
	room_type = ,
	retain_time = ,
	base_coin = ,
	name = ,
	game_type = 0,
    max_player_num = 0,
    create_user_rid = ,
    create_user_rolename = ,
    create_user_logo=,
    create_time = ,
    create_table_id = ,
   	action_timeout = ,       --玩家操作限时
	action_timeout_count = , --玩家可操作超时次数
	brand_level = ,          --牌级
	min_carry_coin = ,       --最小携带金币	
	....
}
]]
function TableCMD.start(conf, roomsvr_id, id)
	if conf == nil or roomsvr_id == nil then
		filelog.sys_error(filename.."conf == nil or roomsvr_id == nil")
		base.skynet_retpack(false)
		return
	end

	if id ~= nil then
		conf.id = id
	end

	local server = msghelper:get_server()

	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")

	roomtablelogic.init(server.table_data, conf, roomsvr_id)	
    --上报状态
    msghelper:report_table_state()
	
	base.skynet_retpack(true)
end

function TableCMD.reload(conf)
	local server = msghelper:get_server()
	local table_data = server.table_data
	if table_data == nil then
		filelog.sys_error("the table data is nil")
	end

	if conf.version <= table_data.conf.version then
		return
		filelog.sys_error("version error")
	end 
	--TO ADD 添加reload操作
	table_data.is_reload = true
	table_data.reload_conf = conf
	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")
	roomtablelogic.reload(table_data,conf)
end


function TableCMD.delete(...)
	--上报桌子管理器房间被删除
	local server = msghelper:get_server()
	local table_data = server.table_data
	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")


	if roomtablelogic.is_onegameend(table_data) == true then
		msghelper:DBinsert_player_game_result(table_data)
		--------------------------------xj 
		-- if pcall(msghelper:DBinsert_player_game_result(...)) then --战绩存储
		-- 	filelog.sys_info("保护措施：gamerult save success")
		-- else
		-- 	filelog.sys_info("保护措施：gamerult save failure")
		-- end
		-- --------------------------------xj
		
		for _, seat in ipairs(table_data.seats) do
			if seat.state > ESeatState.SEAT_STATE_NO_PLAYER then
				roomtablelogic.passive_standuptable(table_data, seat, EStandupReason.STANDUP_REASON_TABLEDELETE)
			end
		end
		local waits = tabletool.deepcopy(table_data.waits)
		for i,v in pairs(waits) do   --旁观
			roomtablelogic.passive_leavetable(table_data,i,1)
		end
	else
		table_data.end_delete = 1     --设置删除桌子的标志，等待游戏结束
		return
	end

	msgproxy.sendrpc_broadcastmsgto_tablesvrd("delete", table_data.svr_id , table_data.id)
	
	--检查桌子当前是否能够删除

	--检查游戏是否结束

	--踢出座位上的玩家

	--msgproxyrpc.sendrpc_broadcastmsgto_tablesvrd("delete", table_data.svr_id , table_data.id)

	--通知roomsvrd删除table
	skynet.send(table_data.svr_id, "lua", "cmd", "delete_table", table_data.id)
		
	--删除桌子前清除桌子的状态
	roomtablelogic.clear(table_data)
	--延迟释放桌子
	skynet.sleep(10)
	
	server:exit_service()
end

return TableCMD