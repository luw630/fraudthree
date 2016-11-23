local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "tablehelper"
local logicmng = require "logicmng"
local timer = require "timer"
require "enum"

local filename = "tabletimer.lua"

local TableTimer = {}

function TableTimer.process(session, source, event, ...)
	local f = TableTimer[event] 
	if f == nil then
		filelog.sys_error(filename.." TableTimer.process invalid event:"..event)
		return nil
	end
	f(...)	 
end

function TableTimer.deal_ready(timerid, request)
	local server = msghelper:get_server()
	local table_data = server.table_data
	local seat = table_data.seats[request.roomsvr_seat_index]
	if seat.rid ~= request.rid 
		or seat.ready_timer_id ~= timerid then
		return
	end
	seat.ready_timer_id = -1

	--将玩家站起来
	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")
	roomtablelogic.passive_standuptable(table_data, seat, EStandupReason.STANDUP_REASON_READYTIMEOUT_STANDUP)
end

function TableTimer.doaction(timerid, request)
	local server = msghelper:get_server()
	local table_data = server.table_data
	local seat = table_data.seats[request.roomsvr_seat_index]
	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")
	
	if table_data.state ~= ETableState.TABLE_STATE_WAIT_CLIENT_ACTION 
		or table_data.action_seat_index ~= request.roomsvr_seat_index
		or request.rid ~= table_data.seats[table_data.action_seat_index].rid then
		return
	end

	if roomtablelogic.is_onegameend(table_data) == true then
		return
	end
	
	if table_data.timer_id >= 0 then
		timer.cleartimer(table_data.timer_id)
		table_data.timer_id = -1	
	end

	table_data.action_type = EActionType.ACTION_TYPE_FOLD 
	table_data.state = ETableState.TABLE_STATE_CONTINUE

	if seat.is_tuoguan == EBOOL.TRUE then
		seat.timeout_fold = seat.timeout_fold  + 1
		if seat.timeout_fold >= table_data.conf.tuoguan_timeout_count then
			roomtablelogic.passive_standuptable(table_data,seat,EStandupReason.STANDUP_REASON_TIMEOUT_STANDUP)
			return
		end
	end

	
	local roomgamelogic = msghelper:get_game_logic()
	roomgamelogic.run(table_data.gamelogic)
end

function TableTimer.restart_game(timerid, request)
	print("TableTimer.restart_game")
	local server = msghelper:get_server()    
 	local table_data = server.table_data
 	local request = { type = EGameStartType.GAME_START_BYSERVER}
	if table_data.timer_id == timerid then
	    timer.cleartimer(table_data.timer_id)
	    table_data.timer_id = -1
	    local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")
	    roomtablelogic.startgame(table_data,request)
	    return
	end
	filelog.sys_error(" TableTimer.restart_game faile")
end

function TableTimer.delete_table(timerid, request)
    local server = msghelper:get_server()    
    local table_data = server.table_data
    if table_data.delete_table_timer_id == timerid then
        table_data.delete_table_timer_id = -1
        msghelper:event_process("lua", "cmd", "delete")
    end 
end

function TableTimer.onegamerealend(timerid, request)
	local server = msghelper:get_server()
	local table_data = server.table_data
	if table_data.timer_id ~= timerid then
		return
	end
	timer.cleartimer(table_data.timer_id)
	table_data.timer_id = -1
	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")
	table_data.state = ETableState.TABLE_STATE_ONE_GAME_REAL_END
	local roomgamelogic = msghelper:get_game_logic()
	roomgamelogic.run(table_data.gamelogic)
end

return TableTimer