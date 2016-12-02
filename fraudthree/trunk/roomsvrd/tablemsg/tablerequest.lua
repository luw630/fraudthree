local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "tablehelper"
local timer = require "timer"
local timetool = require "timetool"
local configdao = require "configdao"
local base = require "base"
local msgproxy = require "msgproxy"
local logicmng = require "logicmng"
local filename = "tablerequest.lua"
local cardtool = require "cardtool"
local playerdatadao = require "playerdatadao"
require "cardvalue"

require "enum"

local TableRequest = {}

function TableRequest.process(session, source, event, ...)
	local f = TableRequest[event] 
	if f == nil then
		filelog.sys_error(filename.." TableRequest.process invalid event:"..event)
		base.skynet_retpack(nil)
        return nil
	end
	f(...)
end

function TableRequest.disconnect(request)
	local result
	local server = msghelper:get_server()
	local table_data = server.table_data
	local seat
	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")
	if request.id ~= table_data.id then
		base.skynet_retpack(false)		
		return
	end

	seat = roomtablelogic.get_seat_by_rid(table_data, request.rid)

	if seat == nil then
		base.skynet_retpack(false)		
		return		
	end

	if seat.gatesvr_id ~= request.gatesvr_id 
		or seat.agent_address ~= request.agent_address then
		base.skynet_retpack(false)		
		return		
	end
	base.skynet_retpack(true)
	
	roomtablelogic.disconnect(table_data, request, seat)
end
--[[
//请求进入桌子
message EnterTableReq {
	optional Version version = 1;
	optional int32 id = 2;
	optional string roomsvr_id = 3; //房间服务器id
	optional int32  roomsvr_table_address = 4; //桌子的服务器地址 
}

//响应进入桌子
message EnterTableRes {
	optional int32 errcode = 1; //错误原因 0表示成功
	optional string errcodedes = 2; //错误描述	
	optional GameInfo gameinfo = 3;
}
]]
function TableRequest.entertable(request)
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS, 
	}
	local server = msghelper:get_server()
	local table_data = server.table_data
	local seatinfo, seat
	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")
	
	print("request.id "..request.id.." table_data.id  "..table_data.id )
	if request.id ~= table_data.id then
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效请求！"
		base.skynet_retpack(responsemsg, nil)		
		return
	end

	seat = roomtablelogic.get_seat_by_rid(table_data, request.rid)
	
	if seat ~= nil then
		print("seat~=nil")
		seatinfo = {
			index = seat.index,
		}
		seat.gatesvr_id=request.gatesvr_id
		seat.agent_address = request.agent_address
		seat.playerinfo.rolename=request.playerinfo.rolename
		seat.playerinfo.logo=request.playerinfo.logo
		seat.playerinfo.sex=request.playerinfo.sex
	end

	responsemsg.gameinfo = {}
	msghelper:copy_table_gameinfo(responsemsg.gameinfo)

	
	
	base.skynet_retpack(responsemsg, seatinfo)
	roomtablelogic.entertable(table_data, request, seat)
end

function TableRequest.reentertable(request)
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS, 
	}
	local server = msghelper:get_server()
	local table_data = server.table_data
	local seatinfo, seat, waitinfo
	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")

	seat = roomtablelogic.get_seat_by_rid(table_data, request.rid)
    waitinfo = table_data.waits[request.rid]
	if seat ~= nil then
		seatinfo = {
			index = seat.index,
		}
		seat.gatesvr_id=request.gatesvr_id
		seat.agent_address = request.agent_address
		seat.playerinfo.rolename=request.playerinfo.rolename
		seat.playerinfo.logo=request.playerinfo.logo
		seat.playerinfo.sex=request.playerinfo.sex
		if request.coin ~= seat.getcoin then
			roomtablelogic.changePlayerMoney(table_data,seat, (seat.getcoin- request.coin),request.coin, seat.getcoin,
	 EReasonChangeCurrency.CHANGE_CURRENCY_GATESERVERRESTART,0 )
		end
	elseif waitinfo ~= nil then
		waitinfo.gatesvr_id=request.gatesvr_id
		waitinfo.agent_address = request.agent_address
		waitinfo.playerinfo.rolename=request.playerinfo.rolename
		waitinfo.playerinfo.logo=request.playerinfo.logo
		waitinfo.playerinfo.sex=request.playerinfo.sex	

		filelog.sys_info("reentertable waitinfo",waitinfo)	
	end

	if waitinfo == nil and seat == nil then
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效的请求！"
		base.skynet_retpack(responsemsg, seatinfo)
		return
	end

	responsemsg.gameinfo = {}
	msghelper:copy_table_gameinfo(responsemsg.gameinfo)
	base.skynet_retpack(responsemsg, seatinfo)
	if seat ~= nil then
		roomtablelogic.reentertable(table_data, request, seat)	 
	end
end

--[[
//请求离开桌子
message LeaveTableReq {
	optional Version version = 1;	
	optional int32 id = 2;
	optional string roomsvr_id = 3; //房间服务器id
	optional int32  roomsvr_table_address = 4; //桌子的服务器地址
}

//响应离开桌子
message LeaveTableReq {
	optional int32 errcode = 1; //错误原因 0表示成功
	optional string errcodedes = 2; //错误描述			
}
]]
function TableRequest.leavetable(request)
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS, 
	}
	local server = msghelper:get_server()
	local table_data = server.table_data
	local seat
	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")

	if request.id ~= table_data.id then
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效请求！"
		base.skynet_retpack(responsemsg)		
		return
	end

	seat = roomtablelogic.get_seat_by_rid(table_data, request.rid)

	if seat == nil then
		roomtablelogic.leavetable(table_data, request, seat)
		base.skynet_retpack(responsemsg)		
		return
	end

	roomtablelogic.standuptable(table_data, request, seat)
	roomtablelogic.leavetable(table_data, request, seat)	
	base.skynet_retpack(responsemsg)		
end

--[[
//请求坐入桌子
message SitdownTableReq {
	optional Version version = 1;
	optional int32 id = 2;
	optional string roomsvr_id = 3; //房间服务器id
	optional int32  roomsvr_table_address = 4; //桌子的服务器地址
	optional int32  roomsvr_seat_index = 5; //指定桌位号
}

//响应坐入桌子
message SitdownTableRes {
	optional int32 errcode = 1; //错误原因 0表示成功
	optional string errcodedes = 2; //错误描述	
}
]]
function TableRequest.sitdowntable(request)
 	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS, 
	}
	local server = msghelper:get_server()
	local table_data = server.table_data
	local seatinfo, seat
	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")
	

	seat = roomtablelogic.get_seat_by_rid(table_data, request.rid)

	if seat ~= nil then
		seatinfo = {
			index = seat.index
		}
		seat.gatesvr_id=request.gatesvr_id
		seat.agent_address = request.agent_address
		seat.playerinfo.rolename=request.playerinfo.rolename
		seat.playerinfo.logo=request.playerinfo.logo
		seat.playerinfo.sex=request.playerinfo.sex
		base.skynet_retpack(responsemsg, seatinfo)
	else
		--判断玩家金币是否够最小携带
		if request.coin ~= nil and request.coin < table_data.conf.min_carry_coin then
			responsemsg.errcode = EErrCode.ERR_NOTENOUGH_COIN
			responsemsg.errcodedes = "当前没有足够的金币！"
			base.skynet_retpack(responsemsg, seatinfo)
			return			
		end
		
		if roomtablelogic.is_full(table_data) then
			responsemsg.errcode = EErrCode.ERR_TABLE_FULL
			responsemsg.errcodedes = "当前桌子已经满了！"
			base.skynet_retpack(responsemsg, seatinfo)
			return
		end

		seat = roomtablelogic.get_emptyseat_by_index(table_data, request.roomsvr_seat_index)
		if seat == nil then
			responsemsg.errcode = EErrCode.ERR_NO_EMPTY_SEAT
			responsemsg.errcodedes = "当前桌子没有空座位了！"
			base.skynet_retpack(responsemsg, seatinfo)
			return			
		end
		seatinfo = {
			index = seat.index,
		}

		--增加桌子人数计数 
		table_data.sitdown_player_num = table_data.sitdown_player_num + 1		
	end
	base.skynet_retpack(responsemsg, seatinfo)

	roomtablelogic.sitdowntable(table_data, request, seat)

end

--[[
//请求从桌子站起
message StandupTableReq {
	optional Version version = 1;
	optional int32 id = 2;
	optional string roomsvr_id = 3; //房间服务器id
	optional int32  roomsvr_table_address = 4; //桌子的服务器地址
}

//响应从桌子站起
message StandupTableRes {
	optional int32 errcode = 1; //错误原因 0表示成功
	optional string errcodedes = 2; //错误描述		
}
]]
function TableRequest.standuptable(request)
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS, 
	}
	local server = msghelper:get_server()
	local table_data = server.table_data
	local seat
	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")

	seat = roomtablelogic.get_seat_by_rid(table_data, request.rid)

	if seat == nil then
		responsemsg.errcode = EErrCode.ERR_HAD_STANDUP
		responsemsg.errcodedes = "你已经站起了！"
		base.skynet_retpack(responsemsg)
		return
	end
	print("TableRequest.standuptable")
	roomtablelogic.standuptable(table_data, request, seat)
	base.skynet_retpack(responsemsg)
end
--[[
//桌主请求开始游戏
message StartGameReq {
	optional Version version = 1;	
	optional int32 id = 2;
	optional string roomsvr_id = 3; //房间服务器id
	optional int32  roomsvr_table_address = 4; //桌子的服务器地址	
}

//响应桌主开始游戏
message StartGameRes {
	optional int32 errcode = 1; //错误原因 0表示成功
	optional string errcodedes = 2; //错误描述		
}
]]
function TableRequest.startgame(request)
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS, 
	}
	local server = msghelper:get_server()
	local table_data = server.table_data

	if table_data.state ~= ETableState.TABLE_STATE_WAIT_MIN_PLAYER then
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效请求！"
		base.skynet_retpack(responsemsg)
		return		
	end
	base.skynet_retpack(responsemsg)
	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")
	roomtablelogic.startgame(table_data, request)
end

function TableRequest.readygame(request)
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS, 
	}
	local server = msghelper:get_server()
	local table_data = server.table_data

	if table_data.state ~= ETableState.TABLE_STATE_WAIT_ALL_READY then
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效请求！"
		base.skynet_retpack(responsemsg)
		return		
	end

	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")
	if (not roomtablelogic.readygame(table_data, request)) then
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效请求！"
		base.skynet_retpack(responsemsg)
		return		
	end

	base.skynet_retpack(responsemsg)
end

function TableRequest.doaction(request)
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS, 
	}
	local server = msghelper:get_server()
	local table_data = server.table_data
	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")
	local roomseatlogic = logicmng.get_logicbyname("roomseatlogic")
	local gamelogic = msghelper:get_game_logic()
	local seat = roomtablelogic.get_seat_by_rid(table_data, request.rid)
	filelog.sys_info("TableRequest.doaction",request)
	if seat == nil then
		responsemsg.errcode = EErrCode.ERR_HAD_STANDUP
		responsemsg.errcodedes = "玩家不在座位上！"
		base.skynet_retpack(responsemsg)
		return
	end

	if  request.action_type == EActionType.ACTION_TYPE_SHOWCARD then
		if roomtablelogic.is_onegameend(table_data) == false then
			responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
			responsemsg.errcodedes = "无效请求！"
			base.skynet_retpack(responsemsg)
			return
		end
		base.skynet_retpack(responsemsg)
		roomtablelogic.showcard(table_data,request,seat)
		return
	end

	if gamelogic.is_ingame(table_data,seat) == false then --是否在游戏，包含弃牌等状态
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效参数！"
		base.skynet_retpack(responsemsg)
		return	
	end


	if table_data.state ~= ETableState.TABLE_STATE_WAIT_CLIENT_ACTION --是否轮到这个玩家操作
		or table_data.action_seat_index ~= seat.index then

		--玩家看牌，自动跟注，弃牌
		if  request.action_type >= EActionType.ACTION_TYPE_SEECARDS and  request.action_type <= 
			EActionType.ACTION_TYPE_FOLD then
			base.skynet_retpack(responsemsg)
			roomtablelogic.doaction(table_data, request, seat)	
			return
		end
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效请求！"
		base.skynet_retpack(responsemsg)
		return		
	end
	
	--玩家跟注或者加注
	if  request.action_type == EActionType.ACTION_TYPE_CALL or request.action_type == 
		EActionType.ACTION_TYPE_RAISE  then

		if request.action_param <= 0 then
			responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
			responsemsg.errcodedes = "无效参数！"
			base.skynet_retpack(responsemsg)
			return	
		end

		if request.action_type == EActionType.ACTION_TYPE_CALL  then
			if seat.seecards > 0 then
				if seat.coin < table_data.cur_bets*2 then
					responsemsg.errcode = EErrCode.ERR_NOTENOUGH_COIN
					responsemsg.errcodedes = "金币不足"
					base.skynet_retpack(responsemsg)
					return		
				end
			else
				if seat.coin < table_data.cur_bets then
					responsemsg.errcode = EErrCode.ERR_NOTENOUGH_COIN
					responsemsg.errcodedes = "金币不足"
					base.skynet_retpack(responsemsg)
					return		
				end
			end
		elseif request.action_type == EActionType.ACTION_TYPE_RAISE  then
			if seat.seecards > 0 then
				if seat.coin < table_data.conf.base_coin*request.action_param*2 then
					responsemsg.errcode = EErrCode.ERR_NOTENOUGH_COIN
					responsemsg.errcodedes = "金币不足"
					base.skynet_retpack(responsemsg)
					return		
				end
			else
				if seat.coin < table_data.conf.base_coin*request.action_param then
					responsemsg.errcode = EErrCode.ERR_NOTENOUGH_COIN
					responsemsg.errcodedes = "金币不足"
					base.skynet_retpack(responsemsg)
					return		
				end
			end
		end
	end

	if  request.action_type == EActionType.ACTION_TYPE_RUSH then --血拼
		local needbets = 0
		if table_data.rush_bets > 0 then
			if seat.seecards > 0 then 
				needbets = table_data.cur_bets * 4
			else
				needbets = table_data.cur_bets * 2
			end
		else
			needbets = table_data.conf.base_coin * 50 
		end

		if seat.coin < needbets then
			responsemsg.errcode = EErrCode.ERR_NOTENOUGH_COIN
			responsemsg.errcodedes = "金币不足"
			base.skynet_retpack(responsemsg)
			return	
		end

	end

	--玩家比牌
	if request.action_type == EActionType.ACTION_TYPE_COMPARE then
		if request.action_param <= 0 then
			responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
			responsemsg.errcodedes = "无效参数！"
			base.skynet_retpack(responsemsg)
			return	
		end
		local comparseat = table_data.seats[request.action_param]
		if gamelogic.is_playeing(table_data,comparseat) == false then
			responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
			responsemsg.errcodedes = "无效参数！"
			base.skynet_retpack(responsemsg)
			return	
		end
	end

	if request.action_type == EActionType.ACTION_TYPE_FORCECOMPARE then
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效请求！"
		base.skynet_retpack(responsemsg)
		return	
	end

	base.skynet_retpack(responsemsg)
	roomtablelogic.doaction(table_data, request, seat)		
end



-- //玩家向桌主申请坐入桌子
-- message QuestSitTableReq {
-- 	optional Version version = 1;
-- 	optional int32 id = 2;
-- 	optional string roomsvr_id = 3; //房间服务器id
-- 	optional int32  roomsvr_table_address = 4; //桌子的服务器地址
-- 	optional string quest_rolename = 5; // 请求的玩家
-- 	optional int32 quest_rid = 6; // 请求的玩家rid
-- }

-- //通知桌主玩家申请进入桌子
-- message RequestSitTableNtc {
-- 	optional Version version = 1;
-- 	optional int32 id = 2;
-- 	optional string roomsvr_id = 3; //房间服务器id
-- 	optional int32  roomsvr_table_address = 4; //桌子的服务器地址
-- 	optional string quest_rolename = 5; // 请求的玩家
-- 	optional int32 quest_rid = 6; // 请求的玩家rid
-- }


function TableRequest.requestsitdown( request )
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS, 
	}
	local server = msghelper:get_server()
	local table_data = server.table_data

	 if table_data.conf.room_type == ERoomType.ROOM_TYPE_COMMON or request.rid == table_data.conf.create_user_rid  then
	 	TableRequest.sitdowntable(request)
		return
	 end

	 if table_data.conf.accesscontrol == 2 then
	 	TableRequest.sitdowntable(request)
		return
	 end

	local bnew,online = playerdatadao.query_player_online(table_data.conf.create_user_rid)
	if online ~= nil then
		local requestsittable= 
		{
			id = table_data.id,
			roomsvr_id = request.roomsvr_id,
			roomsvr_table_address = request.roomsvr_table_address,
			quest_rolename = request.sitdown_rolename,
			quest_rid = request.rid,
		}
		 msgproxy.sendrpc_noticemsgto_gatesvrd(online.gatesvr_id,online.gatesvr_service_address, "RequestSitTableNtc", requestsittable)	
	else
		responsemsg.errcode = EErrCode.ERR_PLAYER_OFFLINE
		responsemsg.errcodedes = "桌主不在线"
	end
	base.skynet_retpack(responsemsg, nil)	

end

--[[
// 玩家请求发送聊天信息
message SendMessageReq {
	optional Version version = 1;
	optional string messages = 2; //json 串
	optional int32 chat_type = 3; //聊天类型(备用)
}

// 玩家发送聊天信息回应
message SendMessageRes {
	optional int32 errcode = 1;
	optional string errcodedes = 2;
}


--]]
function TableRequest.sendTableMessage(request)
	-- body
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS,
	}
	local server = msghelper:get_server()
	local table_data = server.table_data
	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")
	local seat = roomtablelogic.get_seat_by_rid(table_data, request.rid)
	if seat == nil  then
		responsemsg.errcode = EErrCode.ERR_NOT_INTABLE
		responsemsg.errcodedes = "你已经不在桌内！"
		base.skynet_retpack(responsemsg)
		return
	end
	------向房间内的玩家广播消息
	-------roomtablelogic.sendMessage(table_data, request.messages)
	base.skynet_retpack(responsemsg)
	local messageresponmsg = {
		rid = seat.rid,
		seat_index = seat.index,
		messages = request.messages,
		chat_type = request.chat_type,
	}
	msghelper:sendmsg_to_alltableplayer("PlayerTableMessageNtc",messageresponmsg)
end


return TableRequest