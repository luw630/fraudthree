local logicmng = require "logicmng"
local tabletool = require "tabletool"
local timetool = require "timetool"
local msghelper = require "tablehelper"
local timer = require "timer"
local filelog = require "filelog"
local base = require "base"
local cardtool = require "cardtool"
local msgproxy = require "msgproxy"
local skynet = require "skynet"
local playerdataDAO = require "playerdatadao"
local gamelog = require "gamelog"
require "enum"
local RoomTableLogic = {}

function RoomTableLogic.init(tableobj, conf, roomsvr_id)
	if conf == nil or roomsvr_id == nil then
		filelog.sys_error("RoomTableLogic.init conf == nil")
		return false
	end
	local roomseatlogic = logicmng.get_logicbyname("roomseatlogic")
	tableobj.id = conf.id
	tableobj.svr_id = roomsvr_id
	tableobj.state = ETableState.TABLE_STATE_WAIT_MIN_PLAYER

	--初始化座位
	local seatobj = require("object.seatobj")
	local seat
	local count = 1
    while count <= conf.max_player_num do
    	seat = seatobj:new({

    		----------xj-----
    		coin_base = 0,  --携带进桌的金币的备份
       		----------xj-----
    		--Add 座位其他变量
    		timeout_count = 0, --超时次数
    		--[[
				EWinResult = {
					WIN_RESULT_UNKNOW = 0,
					WIN_RESULT_WIN = 1,
					WIN_RESULT_LOSE = 2,
				}
    		]]
    		win = 0,        --表示玩家胜利还是失败
    		coin = 0,       --玩家携带进桌的金币
    		
    		team = 0,       --玩家的组别
    		cards = {}, 	--所持有的牌
    		ready_timer_id = -1, --准备倒计时定时器
    		rank = 0,		--出完牌顺序
    		ready_to_time = 0, --准备到期时间
    		is_ready = EBOOL.FALSE, 	--是否准备
    		getcoin = 0,		--当前局活的金币
    		timeout_fold = 0,	--超时弃牌次数
    	})
    	roomseatlogic.init(seat, count)
    	table.insert(tableobj.seats, seat)

    	-- if seat.index == 1 or seat.index == 3 then
    	-- 	seat.team = ETeam.TEAM_A
    	-- else
    	-- 	seat.team = ETeam.TEAM_B
    	-- end
		count = count + 1
    end

	tableobj.conf = tabletool.deepcopy(conf)
	tableobj.the_round = 1;    --当前游戏轮数
	tableobj.makers = 0   --庄家
	tableobj.playernum = 0 --玩家数量
	

	local roomgamelogic = msghelper:get_game_logic()	
	local game = require("object.gameobj")
	tableobj.gamelogic = game:new()
	roomgamelogic.init(tableobj.gamelogic, tableobj)

	if conf.retain_time ~= nil and conf.retain_time > 0 then
    		tableobj.delete_table_timer_id = timer.settimer(conf.retain_time*100, "delete_table")
		tableobj.retain_to_time = timetool.get_time() + conf.retain_time
	end

	--testcode

	-- if conf.force_overturns == nil then
	-- 	tableobj.conf.force_overturns  = 5	
	-- end

	return true
end

function RoomTableLogic.clear(tableobj)
	if tableobj.timer_id > 0 then
		timer.cleartimer(tableobj.timer_id)
		tableobj.timer_id = -1
	end

	if tableobj.delete_table_timer_id > 0 then
		timer.cleartimer(tableobj.delete_table_timer_id)
		tableobj.delete_table_timer_id = -1
	end

	for _, seat in pairs(tableobj.seats) do
		if seat.ready_timer_id > 0 then
			timer.cleartimer(seat.ready_timer_id)
			seat.ready_timer_id = -1
		end
	end

	for k,v in pairs(tableobj) do
		tableobj[k] = nil
	end
end

--[[
	seat: nil表示否， 非nil表示是
]]
function RoomTableLogic.entertable(tableobj, request, seat)
	if seat and seat.is_tuoguan == EBOOL.TRUE then
		seat.is_tuoguan = EBOOL.FALSE

		--TO ADD 视情况添加解除托管处理 
	else
		local waitinfo = tableobj.waits[request.rid]
		if waitinfo == nil then
			tableobj.waits[request.rid] = {}
			waitinfo = tableobj.waits[request.rid]
			waitinfo.playerinfo = {}
			tableobj.waits[request.rid] = waitinfo			
		end
		waitinfo.rid = request.rid
		waitinfo.gatesvr_id = request.gatesvr_id
		waitinfo.agent_address = request.agent_address
		waitinfo.playerinfo.rolename=request.playerinfo.rolename
		waitinfo.playerinfo.logo=request.playerinfo.rolename
		waitinfo.playerinfo.sex=request.playerinfo.sex
	end
end

function RoomTableLogic.reentertable(tableobj, request, seat)
	
	if seat.is_tuoguan == EBOOL.TRUE then
		seat.is_tuoguan = EBOOL.FALSE
		seat.timeout_fold = 0
		--TO ADD 添加托管处理
	end

	local roomseatlogic = logicmng.get_logicbyname("roomseatlogic")

	if not RoomTableLogic.is_onegameend(tableobj) then
		--把牌发给玩家
		roomseatlogic.DealCards(seat)
		if tableobj.action_seat_index == seat.index then
			--通知玩家当前该他操作
			local doactionntcmsg = {
				rid = tableobj.seats[tableobj.action_seat_index].rid,
				roomsvr_seat_index = tableobj.action_seat_index,
				action_to_time = tableobj.action_to_time,
				game_turns = tableobj.turns,
			}
			msghelper:sendmsg_to_tableplayer(seat, "DoactionNtc", doactionntcmsg)
		end
	end
end

--被动离开桌子，使用该接口时玩家必须是在旁观中
--记住使用者如果循环遍历旁观队列一定要使用原队列的copy队列
function RoomTableLogic.passive_leavetable(tableobj, rid, is_sendto_client)
	local leavetablemsg = {
		roomsvr_id = tableobj.svr_id,
		roomsvr_table_id = tableobj.id,
		roomsvr_table_address = skynet.self(),
		is_sendto_client = is_sendto_client,
		rid = rid,
	}
	msghelper:sendmsg_to_waitplayer(tableobj.waits[rid], "leavetable", leavetablemsg)
	tableobj.waits[rid] = nil	
end

function RoomTableLogic.leavetable(tableobj, request, seat)
	tableobj.waits[request.rid] = nil
	local leavetablentc = {rid = request.rid}
	msghelper:sendmsg_to_alltableplayer("LeaveTableNtc",leavetablentc)
end

--[[

]]
function RoomTableLogic.sitdowntable(tableobj, request, seat)
	tableobj.waits[request.rid] = nil

	seat.rid = request.rid
	seat.gatesvr_id=request.gatesvr_id
	seat.agent_address = request.agent_address
	seat.playerinfo.rolename=request.playerinfo.rolename
	seat.playerinfo.logo=request.playerinfo.logo
	seat.playerinfo.sex=request.playerinfo.sex
	seat.state = ESeatState.SEAT_STATE_WAIT_START
	seat.coin = request.coin
	

	seat.ready_to_time = timetool.get_time() + tableobj.conf.ready_timeout

	local noticemsg = {
		rid = seat.rid,
		seatinfo = {},
		tableplayerinfo = {},
	}
	msghelper:copy_seatinfo(noticemsg.seatinfo, seat)
	msghelper:copy_tableplayerinfo(noticemsg.tableplayerinfo, seat)
	msghelper:sendmsg_to_alltableplayer("SitdownTableNtc", noticemsg)

	if seat.is_tuoguan == EBOOL.TRUE then
		seat.is_tuoguan = EBOOL.FALSE
		--TO ADD 添加托管处理
	end

	--通知client倒计时，同时设置准备超时定时器
	-- if seat.ready_timer_id > 0 then
	-- 	timer.cleartimer(seat.ready_timer_id)
	-- 	seat.ready_timer_id = -1
	-- end
	-- local deal_ready_msg = {
	-- 	rid = seat.rid,
	-- 	roomsvr_seat_index = seat.index,
	-- }
	-- seat.ready_timer_id = timer.settimer(tableobj.conf.ready_timeout*100, "deal_ready", deal_ready_msg)
	-- local readycountdownntcmsg = {
	-- 	rid = seat.rid,
	-- 	roomsvr_seat_index = seat.index,
	-- 	timeout = seat.ready_to_time,	
	-- }
	-- msghelper:sendmsg_to_alltableplayer("ReadyCountDownNtc", readycountdownntcmsg)

	local roomgamelogic = msghelper:get_game_logic()
	roomgamelogic.onsitdowntable(tableobj.gamelogic, seat)

	msghelper:report_table_state()
end

function RoomTableLogic.passive_standuptable(tableobj, seat, reason)
	local roomgamelogic = msghelper:get_game_logic()

	if not RoomTableLogic.is_onegameend(tableobj) then
		if roomgamelogic.is_ingame(tableobj.gamelogic,seat) == true then
			roomgamelogic.onstanduptable(tableobj.gamelogic,seat)
			seat.state = ESeatState.SEAT_STATE_ESCAPE
		end
	end

	tableobj.sitdown_player_num = tableobj.sitdown_player_num - 1 

	--通知agent清除座位号
	msghelper:sendmsg_to_tableplayer(seat, "standuptable",
									 {
									 	rid=seat.rid,
									 	roomsvr_seat_index = seat.index,
									 	roomsvr_table_id = tableobj.conf.id,
									 	roomsvr_id = tableobj.svr_id,
									 })	

	local noticemsg = {
		rid = seat.rid, 
		roomsvr_seat_index = seat.index,
		state = seat.state,
		reason = reason,
	}
	msghelper:sendmsg_to_alltableplayer("StandupTableNtc", noticemsg)

	seat.state = ESeatState.SEAT_STATE_NO_PLAYER

	if tableobj.waits[seat.rid] == nil then
		local waitinfo = {
			playerinfo = {},
		}
		tableobj.waits[seat.rid] = waitinfo

		waitinfo.rid = seat.rid
		waitinfo.gatesvr_id = seat.gatesvr_id
		waitinfo.agent_address = seat.agent_address
		waitinfo.playerinfo.rolename=seat.playerinfo.rolename
		waitinfo.playerinfo.logo=seat.playerinfo.rolename
		waitinfo.playerinfo.sex=seat.playerinfo.sex
	end

	--初始化座位数据
	roomgamelogic.standup_clear_seat(tableobj.gamelogic, seat)

	msghelper:report_table_state()
end

function RoomTableLogic.standuptable(tableobj, request, seat)
	local roomgamelogic = msghelper:get_game_logic()
	if not RoomTableLogic.is_onegameend(tableobj) then
		if roomgamelogic.is_ingame(tableobj.gamelogic,seat) == true then
			roomgamelogic.onstanduptable(tableobj.gamelogic,seat)
			seat.state = ESeatState.SEAT_STATE_ESCAPE
		end
	end
	
	tableobj.sitdown_player_num = tableobj.sitdown_player_num - 1 

	local noticemsg = {
		rid = seat.rid, 
		roomsvr_seat_index = seat.index,
		state = seat.state,
		reason = EStandupReason.STANDUP_REASON_ONSTANDUP,
	}
	msghelper:sendmsg_to_alltableplayer("StandupTableNtc", noticemsg)

	seat.state = ESeatState.SEAT_STATE_NO_PLAYER


	if tableobj.waits[seat.rid] == nil then
		local waitinfo = {
			playerinfo = {},
		}
		tableobj.waits[seat.rid] = waitinfo

		waitinfo.rid = seat.rid
		waitinfo.gatesvr_id = seat.gatesvr_id
		waitinfo.agent_address = seat.agent_address
		waitinfo.playerinfo.rolename=seat.playerinfo.rolename
		waitinfo.playerinfo.logo=seat.playerinfo.rolename
		waitinfo.playerinfo.sex=seat.playerinfo.sex
	end
	--初始化座位数据
	roomgamelogic.standup_clear_seat(tableobj.gamelogic, seat)
	msghelper:report_table_state()


end

function RoomTableLogic.get_all_playernum(tableobj )
	
end

function RoomTableLogic.startgame(tableobj, request)
	if RoomTableLogic.is_canstartgame(tableobj) then
		local roomgamelogic = msghelper:get_game_logic()
		tableobj.state = ETableState.TABLE_STATE_GAME_START
		RoomTableLogic.randCardListForSeat(tableobj)
		roomgamelogic.run(tableobj.gamelogic)
	else
		if request.type == EGameStartType.GAME_START_BYSERVER then  
			if tableobj.timer_id >= 0 then
				timer.cleartimer(tableobj.timer_id)
			end
			tableobj.timer_id = timer.settimer(10*100, "restart_game")
		end
		tableobj.state = ETableState.TABLE_STATE_WAIT_MIN_PLAYER
	end
end

function RoomTableLogic.showcard( tableobj, request, seat )	
	local roomgamelogic = msghelper:get_game_logic()
	roomgamelogic.showcard(tableobj.gamelogic,seat)	
end


function RoomTableLogic.doaction(tableobj, request, seat)
	local roomgamelogic = msghelper:get_game_logic()
	if  tableobj.action_seat_index ~= seat.index then
		if request.action_type > EActionType.ACTION_TYPE_RUSH and request.action_type <= 
			EActionType.ACTION_TYPE_FOLD then
			roomgamelogic.aloneaction(tableobj.gamelogic,request)
			return
		end
	end
	tableobj.action_type = request.action_type
	tableobj.action_param = request.action_param
	tableobj.state = ETableState.TABLE_STATE_CONTINUE
	roomgamelogic.run(tableobj.gamelogic)
end

function RoomTableLogic.disconnect(tableobj, request, seat)
	---不能将 seat.gatesvr_id,seat.agent_address 置为无效,否则,游戏结束时,无法通知agent更新玩家数据
	-- seat.gatesvr_id = ""
	-- seat.agent_address = -1 tuoguan_timeout_count
	seat.is_tuoguan = EBOOL.TRUE

--	request.action_type = EActionType.ACTION_TYPE_FOLD
--	RoomTableLogic.doaction(tableobj,request,seat)
--	seat.timeout_fold = seat.timeout_fold  + 1
	
	--TO ADD添加玩家掉线处理
end

function RoomTableLogic.get_svr_id(tableobj)
	return tableobj.svr_id
end

function RoomTableLogic.get_sitdown_player_num(tableobj)
	return tableobj.sitdown_player_num
end

--根据指定桌位号获得一张空座位
function RoomTableLogic.get_emptyseat_by_index(tableobj, index)
	local roomseatlogic = logicmng.get_logicbyname("roomseatlogic")
	if index > 0 then
		local seat = tableobj.seats[index]
		if roomseatlogic.is_empty(seat) then
			return seat
		end	
	end

	 for index, seat in pairs(tableobj.seats) do
		if roomseatlogic.is_empty(seat) then
			return seat
		end
	end
	-- if index == nil or index <= 0 or index > tableobj.conf.max_player_num then
	-- 	for index, seat in pairs(tableobj.seats) do
	-- 		if roomseatlogic.is_empty(seat) then
	-- 			return seat
	-- 		end
	-- 	end
	-- else
	-- 	local seat = tableobj.seats[index]
	-- 	if roomseatlogic.is_empty(seat) then
	-- 		return seat
	-- 	end
	-- end
	return nil
end

function RoomTableLogic.get_seat_by_rid(tableobj, rid)
	for index, seat in pairs(tableobj.seats) do
		if rid == seat.rid then
			return seat
		end
	end
	return nil
end

--判断桌子是否满了
function RoomTableLogic.is_full(tableobj)
	return (tableobj.sitdown_player_num >= tableobj.conf.max_player_num)
end


--判断当前是否能够开始游戏
function RoomTableLogic.is_canstartgame(tableobj)
	for _, seat in ipairs(tableobj.seats) do
		if seat.state == ESeatState.SEAT_STATE_WAIT_START then
			if seat.coin < tableobj.conf.min_carry_coin then
				RoomTableLogic.passive_standuptable(tableobj, seat, EStandupReason.STANDUP_REASON_MONEYNOTENOUGH)
			end
		end
	end
	return tableobj.sitdown_player_num >= tableobj.conf.min_player_num
end

--判断游戏是否结束
function RoomTableLogic.is_gameend(tableobj)
	if tableobj.state == ETableState.TABLE_STATE_WAIT_MIN_PLAYER 
		or tableobj.state == ETableState.TABLE_STATE_WAIT_GAME_START
		or tableobj.state == ETableState.TABLE_STATE_WAIT_ALL_READY 
		or tableobj.state == ETableState.TABLE_STATE_GAME_END then
		return true
	end

	return false
end

--判断当前局是否已经结束游戏
function RoomTableLogic.is_onegameend(tableobj)
	if tableobj.state == ETableState.TABLE_STATE_ONE_GAME_END 
		or tableobj.state == ETableState.TABLE_STATE_ONE_GAME_REAL_END then
		return true
	end

	if tableobj.state == ETableState.TABLE_STATE_SHOW_TIME  then
		return true
	end

	if tableobj.state == ETableState.TABLE_STATE_WAIT_GAME_END 
		or tableobj.state == ETableState.TABLE_STATE_WAIT_ONE_GAME_REAL_END then
		return true
	end

	return RoomTableLogic.is_gameend(tableobj)
end

function RoomTableLogic.is_firstRound(tableobj)
	return tableobj.the_round == 1;
end




--每个玩家随机牌
function RoomTableLogic.randCardListForSeat(tableobj)
	--local cardBuffer = cardtool.RandCardList(tableobj.conf.create_table_id);
	local cardBuffer = cardtool.RandCardList();
	for i=1,tableobj.conf.max_player_num do
		local seat = tableobj.seats[i]
		if seat.state > ESeatState.SEAT_STATE_NO_PLAYER then
			for j=1,g_PerPlaCardCount do
				local cardVal = cardBuffer[(i - 1) * g_PerPlaCardCount + j];

				local cardType = math.ceil(cardVal / g_CardDivisor);
				if (cardType == ColorType.Heart) then
					cardVal = cardVal % g_HeartDivisor
				elseif (cardType == ColorType.Plum) then
					cardVal = cardVal % g_PlumDivisor
				elseif (cardType == ColorType.Block) then
					cardVal = cardVal % g_BlockDivisor
				elseif (cardType ~= ColorType.Spade) then
					cardType = ColorType.Wang
				end

				local cardinfo =
				{
					card_value = cardVal;
					card_type = cardType;
				};
					
				seat.cards[j] = cardinfo;
			end	
		end

		--filelog.sys_info("randCardListForSeat ",seat.cards)
	end
	
end


function RoomTableLogic.changeMoney(tableobj, seat,changevalue,reason )
	if tableobj.conf.room_type == 2 then 									---如果是朋友桌则执行
		tableobj.conf.coin_realize[seat.rid] =  tableobj.conf.coin_realize[seat.rid] + changevalue
	end
	local beforecoin = seat.coin
	if seat.coin + changevalue >= 0 then
		seat.coin  = seat.coin  + changevalue
	else
		seat.coin = 0
		filelog.sys_error("RoomTableLogic.changeMoney Error",seat.rid,changevalue)
	end
	gamelog.write_player_coinlog(seat.rid, reason, ECurrencyType.CURRENCY_TYPE_COIN, changevalue, beforecoin, seat.coin)
end

--为每个玩家发牌
function RoomTableLogic.dealCardsForPlayer(tableobj)
	local roomseatlogic = logicmng.get_logicbyname("roomseatlogic");

	--每个玩家发牌
	for i=1,tableobj.conf.max_player_num do
		local seat = tableobj.seats[i];
		filelog.sys_info("the seat is "..tostring(seat))
		roomseatlogic.DealCards(seat);
	end
end


function RoomTableLogic.reload(tableobj,conf)
	if (not tableobj.is_reload or not conf) then
		filelog.sys_error("RoomTableLogic reload error")
		return
	end
	--游戏已经结束或者还没有开始
	if RoomTableLogic.is_onegameend(tableobj) then
		tableobj.conf = tabletool.deepcopy(conf)
		tableobj.is_reload = false
	end
end

return RoomTableLogic
