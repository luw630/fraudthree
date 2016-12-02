local logicmng = require "logicmng"
local base = require "base"
local msghelper = require "tablehelper"
local timetool = require "timetool"
local timer = require "timer"
local filelog = require "filelog"
local cardtool = require "cardtool"
local tabletool = require "tabletool"
require "enum"
require "cardvalue"

local RoomGameLogic = {}
local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")
--[[
]]
function RoomGameLogic.init(gameobj, tableobj)
	gameobj.tableobj = tableobj
	gameobj.stateevent[ETableState.TABLE_STATE_GAME_START] = RoomGameLogic.gamestart
	gameobj.stateevent[ETableState.TABLE_STATE_ONE_GAME_START] = RoomGameLogic.onegamestart
	gameobj.stateevent[ETableState.TABLE_STATE_ONE_GAME_END] = RoomGameLogic.onegameend
	gameobj.stateevent[ETableState.TABLE_STATE_ONE_GAME_REAL_END] = RoomGameLogic.onegamerealend
	gameobj.stateevent[ETableState.TABLE_STATE_GAME_END] = RoomGameLogic.gameend
	gameobj.stateevent[ETableState.TABLE_STATE_CONTINUE] = RoomGameLogic.continue
	gameobj.stateevent[ETableState.TABLE_STATE_CONTINUE_AND_STANDUP] = RoomGameLogic.continue_and_standup
	gameobj.stateevent[ETableState.TABLE_STATE_CONTINUE_AND_LEAVE] = RoomGameLogic.continue_and_leave
	return true
end

function RoomGameLogic.run(gameobj)
	local f = nil
	while true do
		if gameobj.tableobj.state == ETableState.TABLE_STATE_WAIT_MIN_PLAYER then
			break
		end

		f = gameobj.stateevent[gameobj.tableobj.state]
		if f == nil then
			break
		end
		f(gameobj)
	end
end

function RoomGameLogic.gamestart(gameobj)
	local tableobj = gameobj.tableobj
	tableobj.state = ETableState.TABLE_STATE_ONE_GAME_START
	tableobj.makers = RoomGameLogic.getnextplayer(tableobj.makers,gameobj)
	 
end

function RoomGameLogic.getnextplayer( seat_index,gameobj ) --获取座位+1 的玩家
	local tableobj = gameobj.tableobj
	local seatindex = seat_index 
	repeat
		seatindex = seatindex + 1
		if seatindex > #tableobj.seats then
			seatindex = 1
		end
		local seat = tableobj.seats[seatindex]
		if seat.state > ESeatState.SEAT_STATE_NO_PLAYER then
			return seatindex
		end
	until seatindex == seat_index
	return nil
end

function RoomGameLogic.getnextgameplayer( seat_index,gameobj ) --获取座位+1 的游戏玩家
	local tableobj = gameobj.tableobj
	local seatindex = seat_index 
	repeat
		seatindex = seatindex + 1
		if seatindex > #tableobj.seats then
			seatindex = 1
		end
		local seat = tableobj.seats[seatindex]
		if  seatindex ~= seat_index then
			if RoomGameLogic.is_playeing(gameobj,seat) == true then
				return seatindex
			end
		end
	until seatindex == seat_index
	return nil
end


function RoomGameLogic.onegamestart(gameobj)
	local tableobj = gameobj.tableobj

	--初始化桌子
	RoomGameLogic.onegamestart_inittable(gameobj)

	for _, seat in ipairs(tableobj.seats) do
		if seat.state == ESeatState.SEAT_STATE_WAIT_START then
			RoomGameLogic.onegamestart_initseat(gameobj, seat)
			tableobj.playernum = tableobj.playernum  + 1
		end
	end
	
	local action_seat_index = RoomGameLogic.getnextplayer(tableobj.makers,gameobj)
	assert(action_seat_index~=nil,"onegamestart action_seat_index == nil")

	tableobj.turns_startindex = action_seat_index
	tableobj.action_seat_index = action_seat_index
	tableobj.action_to_time = timetool.get_time() + tableobj.conf.action_timeout
	

	local gamestartntcmsg = {}
	gamestartntcmsg.gameinfo = {}
	msghelper:copy_table_gameinfo(gamestartntcmsg.gameinfo)
	msghelper:sendmsg_to_alltableplayer("GameStartNtc", gamestartntcmsg)



	--下发当前玩家操作协议	
	local doactionntcmsg = {
		rid = tableobj.seats[action_seat_index].rid,
		roomsvr_seat_index = action_seat_index,
		action_to_time = timetool.get_time() + tableobj.conf.action_timeout,
	}
	msghelper:sendmsg_to_alltableplayer("DoactionNtc", doactionntcmsg)

	tableobj.timer_id = timer.settimer(tableobj.conf.action_timeout*100, "doaction", doactionntcmsg)

	tableobj.state = ETableState.TABLE_STATE_WAIT_CLIENT_ACTION
end



function RoomGameLogic.continue(gameobj)
	local tableobj = gameobj.tableobj
	if tableobj.timer_id >= 0 then
		timer.cleartimer(tableobj.timer_id)
		tableobj.timer_id = -1
	end

	local seat = tableobj.seats[tableobj.action_seat_index]


	local roomseatlogic = logicmng.get_logicbyname("roomseatlogic");

	local hasPlayAll = false
	local is_end_game = false

	local noticemsg = {
		rid = seat.rid,
		roomsvr_seat_index = tableobj.action_seat_index,
		action_type = tableobj.action_type,
		action_param = tableobj.action_param,
		cur_bets = tableobj.cur_bets,
		all_bets = tableobj.all_bets,
	}

	if tableobj.action_type == EActionType.ACTION_TYPE_STANDUP  then --如果玩家站起，设置座位状态
		RoomGameLogic.onstanduptable(gameobj,seat)
		 
	elseif tableobj.action_type == EActionType.ACTION_TYPE_CALL or tableobj.action_type == 
	EActionType.ACTION_TYPE_RAISE  then -------------跟注
		local bets = 0
		if tableobj.action_type == EActionType.ACTION_TYPE_CALL  then
			bets = tableobj.cur_bets
			seat.state = ESeatState.SEAT_STATE_CALL  
		else
			bets = tableobj.conf.base_coin*tableobj.action_param
			seat.state = ESeatState.SEAT_STATE_RAISE  
		end

		if bets > tableobj.cur_bets then --当前的底注增加
			tableobj.cur_bets = bets
		end

		if seat.seecards > 0 then --看牌玩家加倍
			bets = bets * 2
		end
		
		--roomtablelogic.changeMoney(seat,-bets,EReasonChangeCurrency.CHANGE_CURRENCY_SYSTEM_GAME) --扣钱     
		roomtablelogic.changeMoney(tableobj,seat,-bets,EReasonChangeCurrency.CHANGE_CURRENCY_SYSTEM_GAME) --扣钱     
		tableobj.all_bets = tableobj.all_bets + bets  -------------总投注增加

		noticemsg.cur_bets = tableobj.cur_bets
		noticemsg.all_bets = tableobj.all_bets
	elseif tableobj.action_type == EActionType.ACTION_TYPE_COMPARE or tableobj.action_type == 
	EActionType.ACTION_TYPE_FORCECOMPARE then --比牌
		local bets = 0
		if seat.coin >= tableobj.cur_bets then
				bets = tableobj.cur_bets
				-------//
				if seat.seecards > 0 then --看牌玩家加倍
					bets = bets * 2 
				end
				-------//普通的比牌有问题，需要加判断
		else
			bets = seat.coin
		end

		if tableobj.action_type ~= EActionType.ACTION_TYPE_FORCECOMPARE then
			
			--roomtablelogic.changeMoney(seat,-bets,EReasonChangeCurrency.CHANGE_CURRENCY_SYSTEM_GAME)	--扣钱
			roomtablelogic.changeMoney(tableobj,seat,-bets,EReasonChangeCurrency.CHANGE_CURRENCY_SYSTEM_GAME)	--扣钱
			tableobj.all_bets = tableobj.all_bets + bets   --总投注增加
		end

		local compareseat = tableobj.seats[tableobj.action_param]
		if cardtool.isOvercomePrev(seat.cards,compareseat.cards)== true then
			noticemsg.action_param = seat.index
			RoomGameLogic.paymoney(gameobj,compareseat)  
			--filelog.sys_info("card compare win 1",seat.cards,compareseat.cards)	
		else
			noticemsg.action_param = compareseat.index
			RoomGameLogic.paymoney(gameobj,seat)
			--filelog.sys_info("card compare win 2",seat.cards,compareseat.cards)	
		end
		
		--noticemsg.action_param = seat.index
		--RoomGameLogic.paymoney(gameobj,compareseat)  
	elseif tableobj.action_type == EActionType.ACTION_TYPE_RUSH then --血拼
		--rush_seat_index
		local bets = 0
		if tableobj.rush_bets > 0 then
			bets = tableobj.cur_bets * 2
		else
			tableobj.rush_bets = tableobj.cur_bets
			bets = tableobj.conf.base_coin * 50
		end
		tableobj.rush_seat_index = tableobj.action_seat_index
	
		if bets > tableobj.cur_bets then --当前的底注增加
			tableobj.cur_bets = bets
		end

		if seat.seecards > 0 then --看牌玩家加倍
			bets = bets * 2
		end

		--扣钱
		seat.coin = seat.coin - bets       --扣钱
		tableobj.all_bets = tableobj.all_bets + bets --总投注增加
		
		noticemsg.cur_bets = tableobj.cur_bets
		noticemsg.all_bets = tableobj.all_bets
		seat.state = ESeatState.SEAT_STATE_RUSH  

		noticemsg.action_param = ERUSHTYPE.RUSH_STRAT
	elseif tableobj.action_type >= EActionType.ACTION_TYPE_SEECARDS and  tableobj.action_type <= 
		EActionType.ACTION_TYPE_FOLD then
		local request = {
			rid = seat.rid,
			action_type = tableobj.action_type,
		}
		RoomGameLogic.aloneaction(gameobj,request)
		if tableobj.action_type == EActionType.ACTION_TYPE_SEECARDS then --看牌不需切换玩家
			tableobj.state = ETableState.TABLE_STATE_WAIT_CLIENT_ACTION
			return
		end
	end

	msghelper:sendmsg_to_alltableplayer("DoactionResultNtc", noticemsg)

	local isendgame,winseat =RoomGameLogic.canendgame(gameobj)
	if isendgame == 1 then --判断是否结束游戏
		
		--roomtablelogic.changeMoney(winseat,tableobj.all_bets ,EReasonChangeCurrency.CHANGE_CURRENCY_SYSTEM_GAME)
		roomtablelogic.changeMoney(tableobj,winseat,tableobj.all_bets ,EReasonChangeCurrency.CHANGE_CURRENCY_SYSTEM_GAME)
		--winseat.coin = tableobj.all_bets + winseat.coin
		RoomGameLogic.paymoney(gameobj,winseat,1) 
		tableobj.state = ETableState.TABLE_STATE_ONE_GAME_END
		if tableobj.action_type == EActionType.ACTION_TYPE_COMPARE then
			RoomGameLogic.showcard(gameobj,winseat)
		end
		return
	elseif isendgame == 0 then --胜利玩家状态已经改变为等待,没有玩家
		return
	end

	local action_seat_index = tableobj.action_seat_index
	tableobj.action_seat_index = RoomGameLogic.getnextgameplayer(tableobj.action_seat_index,gameobj)
	if tableobj.action_type == EActionType.ACTION_TYPE_COMPARE then
		if noticemsg.action_param == seat.index  then     --玩家比牌胜利继续操作
			tableobj.action_seat_index = action_seat_index
		end
	end

	assert(tableobj.action_seat_index~=nil,"getnextgameplayer index nil")

	tableobj.action_to_time = timetool.get_time() + tableobj.conf.action_timeout

	if tableobj.action_seat_index == tableobj.rush_seat_index then  --血拼结束
		tableobj.rush_seat_index = 0
		tableobj.cur_bets = tableobj.rush_bets 
		tableobj.rush_bets = 0
		local noticemsg = {
			rid = tableobj.seats[tableobj.action_seat_index].rid,
			roomsvr_seat_index = tableobj.action_seat_index,
			action_type = EActionType.ACTION_TYPE_RUSH,
			action_param = ERUSHTYPE.RUSH_END,
			cur_bets = tableobj.cur_bets,
			all_bets = tableobj.all_bets,
		}
		msghelper:sendmsg_to_alltableplayer("DoactionResultNtc", noticemsg)
	end
	
	tableobj.turns_startindex = tableobj.turns_startindex  + 1
	if tableobj.turns_startindex >= tableobj.playernum and tableobj.turns_startindex % tableobj.playernum == 0  then
		tableobj.turns = tableobj.turns + 1
	end

	-- if tableobj.action_seat_index == tableobj.turns_startindex  and 
	-- tableobj.action_type ~= EActionType.ACTION_TYPE_COMPARE then --游戏圈数计数
	-- 	tableobj.turns = tableobj.turns + 1
	-- end

	if tableobj.turns >= tableobj.conf.force_overturns then
		RoomGameLogic.forcecompare(gameobj)
		return
	end

	local doactionntcmsg = {
		rid = tableobj.seats[tableobj.action_seat_index].rid,
		roomsvr_seat_index = tableobj.action_seat_index,
		action_to_time = tableobj.action_to_time,
		game_turns = tableobj.turns,
	}
	msghelper:sendmsg_to_alltableplayer("DoactionNtc", doactionntcmsg)
	filelog.sys_info("DoactionNtc",doactionntcmsg)

	tableobj.timer_id = timer.settimer(tableobj.conf.action_timeout*100, "doaction", doactionntcmsg)
	--print("doaction timeleft "..math.floor(timeout/60))
	tableobj.state = ETableState.TABLE_STATE_WAIT_CLIENT_ACTION

end

function RoomGameLogic.forcecompare( gameobj) --游戏最后1圈时强制比牌
	local tableobj = gameobj.tableobj
	tableobj.action_type = EActionType.ACTION_TYPE_COMPARE
	tableobj.action_param = RoomGameLogic.getnextgameplayer( tableobj.action_seat_index,gameobj)
	assert(tableobj.action_param~=nil,"forcecompare getnextgameplayer index nil")
	tableobj.state = ETableState.TABLE_STATE_CONTINUE
end

function RoomGameLogic.aloneaction( gameobj,request ) --玩家游戏中操作
	local tableobj = gameobj.tableobj
	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")
	local seat = roomtablelogic.get_seat_by_rid(tableobj,request.rid)
	local tablestatus = tableobj.state

	local seatstatusmsg = 
	{
		rid = request.rid,
		roomsvr_seat_index = seat.index,
		seatstatus = seat.state,
	}
	

	if request.action_type == EActionType.ACTION_TYPE_SEECARDS then --看了牌设置状态
		seat.seecards = 1 
		seatstatusmsg.playercards = seat.cards --玩家游戏数据
		seatstatusmsg.seatstatus = seatstatusmsg.seatstatus | 0x100
		msghelper:sendmsg_to_tableplayer(seat,"SeatStatusNtc", seatstatusmsg)

		filelog.sys_info("aloneaction cards ",seat.cards)
		
	elseif  request.action_type == EActionType.ACTION_TYPE_AUTOCALL then --设置自动跟注状态
		if seat.autocall > 0 then
			seat.autocall = 0 
		else
			seat.autocall = 1
		end		
	elseif  request.action_type == EActionType.ACTION_TYPE_FOLD then 
		seat.state = ESeatState.SEAT_STATE_FOLD
		RoomGameLogic.paymoney(gameobj,seat)
	end

	seatstatusmsg.playercards = {}
	seatstatusmsg.seatstatus = seat.state
	if seat.seecards > 0 then
		seatstatusmsg.seatstatus = seatstatusmsg.seatstatus | 0x100
	end

	if seat.autocall > 0 then
		seatstatusmsg.seatstatus = seatstatusmsg.seatstatus | 0x200
	end
	msghelper:sendmsg_to_alltableplayer("SeatStatusNtc", seatstatusmsg)

	local isendgame,winseat =RoomGameLogic.canendgame(gameobj)
	if isendgame == 1 then --判断是否结束游戏
		
		--roomtablelogic.changeMoney(winseat,tableobj.all_bets,EReasonChangeCurrency.CHANGE_CURRENCY_SYSTEM_GAME) --加钱     
		roomtablelogic.changeMoney(tableobj,winseat,tableobj.all_bets,EReasonChangeCurrency.CHANGE_CURRENCY_SYSTEM_GAME) --加钱     
		RoomGameLogic.paymoney(gameobj,winseat,1) 
		tableobj.state = ETableState.TABLE_STATE_ONE_GAME_END
		RoomGameLogic.onegameend(gameobj)
	end
end

function RoomGameLogic.continue_and_standup(gameobj)
	RoomGameLogic.continue(gameobj)
end

function RoomGameLogic.continue_and_leave(gameobj)
	
end

function RoomGameLogic.showcard( gameobj,seat) --玩家show
	local tableobj = gameobj.tableobj
	if tableobj.state == ETableState.TABLE_STATE_SHOW_TIME  or 
	 tableobj.state == ETableState.TABLE_STATE_ONE_GAME_END 	then  
		local cardinfo = {}
		if seat.state == ESeatState.SEAT_STATE_WAIT_START then
			cardinfo.rid = seat.rid
			cardinfo.roomsvr_seat_index = seat.index
			cardinfo.cards = seat.cards	
			msghelper:sendmsg_to_alltableplayer("CardInfoNtc", cardinfo)
		end
	end
end


function RoomGameLogic.onegameend(gameobj)
	local tableobj = gameobj.tableobj
	--结算处理等 1 end 超时设置（比如播放动画）TABLE_STATE_ONE_GAME_REAL_END
	--tableobj.state = ETableState.TABLE_STATE_ONE_GAME_REAL_END
	
	if tableobj.timer_id >= 0 then
		timer.cleartimer(tableobj.timer_id)
		tableobj.timer_id = -1
	end

	--通知玩家接收自己的牌
	local cardinfo = {}
	for _, seat in ipairs(tableobj.seats) do
		if seat.state == ESeatState.SEAT_STATE_WAIT_START then
			if seat.seecards == 0 then
				cardinfo.rid = seat.rid
			   	cardinfo.roomsvr_seat_index = seat.index
			   	cardinfo.cards = seat.cards
			   	msghelper:sendmsg_to_tableplayer(seat,"CardInfoNtc", cardinfo)	
			end
		end
	end

	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")
	tableobj.timer_id = timer.settimer(10*100, "onegamerealend")
	tableobj.state = ETableState.TABLE_STATE_SHOW_TIME

	if tableobj.end_delete > 0 then    --桌子需要删除
		for _, seat in ipairs(tableobj.seats) do
			if seat.state > ESeatState.SEAT_STATE_NO_PLAYER then
				roomtablelogic.passive_standuptable(tableobj,seat,EStandupReason.STANDUP_REASON_TABLEDELETE)
			end
		end
		local waits = tabletool.deepcopy(tableobj.waits)
		for i,v in pairs(waits) do   --旁观
			roomtablelogic.passive_leavetable(tableobj,i,1)
		end
		tableobj.delete_table_timer_id = timer.settimer(1*100, "delete_table")
		tableobj.end_delete = 0
	end

end

function RoomGameLogic.standbynextgame(gameobj)
	local tableobj = gameobj.tableobj
	for _, seat in ipairs(tableobj.seats) do
		if seat.rid > 0 then
			if seat.state ~= ESeatState.SEAT_STATE_WAIT_START then
				return false
			end
		end
	end
	return true
end

function RoomGameLogic.onegamerealend(gameobj)
	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")
	local tableobj = gameobj.tableobj

	tableobj.the_round = tableobj.the_round + 1
	--print("the_round "..tableobj.the_round)
	if RoomGameLogic.standbynextgame(gameobj) == true then
		tableobj.timer_id = timer.settimer(1*100, "restart_game")
		tableobj.state = ETableState.TABLE_STATE_WAIT_GAME_START
	else
		tableobj.state = ETableState.TABLE_STATE_WAIT_MIN_PLAYER
	end
end

function RoomGameLogic.gameend(gameobj) --3 end
--tableobj.state = ETableState.TABLE_STATE_WAIT_ALL_READY
end

function RoomGameLogic.onsitdowntable(gameobj, seat) --如果没有庄家，设置这个玩家为庄
	local tableobj = gameobj.tableobj
	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")
	if gameobj.tableobj.makers == 0 then
		gameobj.tableobj.makers = seat.index
	end

	if tableobj.state == ETableState.TABLE_STATE_WAIT_MIN_PLAYER then
		local request = { type = EGameStartType.GAME_START_BYSERVER}
		roomtablelogic.startgame(gameobj.tableobj,request)
	end
	--print("onsitdowntable "..seat.rid)
end

function RoomGameLogic.onstanduptable(gameobj, seat) --如果血拼，血拼人数减少
	local tableobj = gameobj.tableobj
	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")

	--游戏中站起处理成弃牌
	local request = {
		rid = seat.rid,
		action_type = EActionType.ACTION_TYPE_FOLD,
	}
	RoomGameLogic.aloneaction(gameobj,request)

	if roomtablelogic.is_onegameend(tableobj) == true then
		return
	end

	if seat.index ~= tableobj.action_seat_index then
		return
	end

	tableobj.action_seat_index = RoomGameLogic.getnextgameplayer(tableobj.action_seat_index,gameobj)
	tableobj.action_to_time = timetool.get_time() + tableobj.conf.action_timeout

	local doactionntcmsg = {
		rid = tableobj.seats[tableobj.action_seat_index].rid,
		roomsvr_seat_index = tableobj.action_seat_index,
		action_to_time = tableobj.action_to_time,
	}
	msghelper:sendmsg_to_alltableplayer("DoactionNtc", doactionntcmsg)
	tableobj.timer_id = timer.settimer(tableobj.conf.action_timeout*100, "doaction", doactionntcmsg)
	tableobj.state = ETableState.TABLE_STATE_WAIT_CLIENT_ACTION
end


function RoomGameLogic.canendgame( gameobj )
	local tableobj = gameobj.tableobj
	local playingplayer = 0
	local winseat = nil
	for _, seat in ipairs(tableobj.seats) do
		if RoomGameLogic.is_playeing(gameobj,seat) == true then
			playingplayer = playingplayer + 1
			winseat = seat
		end
	end
	return playingplayer,winseat
end

function RoomGameLogic.is_ingame(gameobj, seat) --在游戏中
	return seat.state >= ESeatState.SEAT_STATE_PLAYING
end

function RoomGameLogic.is_playeing(gameobj, seat ) --正在游戏的牌局中，去除弃牌，比牌失败等状态
	return (seat.state >= ESeatState.SEAT_STATE_PLAYING) and (seat.state < ESeatState.SEAT_STATE_FOLD)
end

function RoomGameLogic.paymoney( gameobj, seat,is_endgame )  --输家给钱
	local tableobj = gameobj.tableobj
	local noticemsg = 
	{
		rid = seat.rid,
		roomsvr_seat_index = seat.index,
		win_money = seat.coin,
		isendgame = 0,
		all_bets = tableobj.all_bets ,
	}

	if is_endgame ~= nil then
		noticemsg.isendgame = 1
	end

	msghelper:sendmsg_to_alltableplayer("GameResultNtc", noticemsg)
	if seat.index == tableobj.rush_seat_index then 
		tableobj.rush_seat_index = RoomGameLogic.getnextgameplayer(seat.index,gameobj)
	end

	tableobj.playernum = tableobj.playernum - 1
	if seat.index <= tableobj.action_seat_index  then
		if tableobj.turns_startindex > 0 then
			tableobj.turns_startindex = tableobj.turns_startindex -1
		end
	end


	seat.state = ESeatState.SEAT_STATE_WAIT_START
	if  (seat.coin- seat.getcoin) < -seat.getcoin then
		filelog.sys_error("RoomGameLogic.paymoney error",seat.rid,tableobj.id)
	end
	roomtablelogic.changePlayerMoney(tableobj,seat, (seat.coin- seat.getcoin),seat.getcoin, seat.coin,
	EReasonChangeCurrency.CHANGE_CURRENCY_SYSTEM_GAME,noticemsg.isendgame )
	seat.getcoin =  seat.coin
end

function RoomGameLogic.onegamestart_initseat(gameobj, seat)
	seat.state = ESeatState.SEAT_STATE_PLAYING
	seat.timeout_count = 0
	seat.win = EComPareResult.WIN_RESULT_UNKNOW
	seat.rank = 0
	--seat.cards = {}
	seat.ready_to_time = 0
	
	--seat.getcoin =  seat.coin
	seat.seecards = 0   --是否看牌
	seat.autocall = 0   --是否自动跟注

	
	--roomtablelogic.changeMoney(seat,-gameobj.tableobj.cur_bets,EReasonChangeCurrency.CHANGE_CURRENCY_SYSTEM_GAME) -- --扣除底注
	--通知客户端扣除底注
	

	roomtablelogic.changeMoney(gameobj.tableobj,seat,-gameobj.tableobj.cur_bets,EReasonChangeCurrency.CHANGE_CURRENCY_SYSTEM_GAME) -- --扣除底注   	
	assert(seat.coin>=0,"onegamestart_initseat coin faile")
	gameobj.tableobj.all_bets = gameobj.tableobj.all_bets + gameobj.tableobj.cur_bets
end

function RoomGameLogic.copy_gameseat( seat,copyseat )
	copyseat.index = seat.index
	copyseat.state = seat.state
	copyseat.timeout_count = seat.timeout_count
	copyseat.win = seat.win
	copyseat.seecards = seat.seecards
	copyseat.autocall = seat.autocall
	copyseat.cards = seat.cards
	copyseat.coin = seat.coin
	copyseat.rid = seat.rid
	copyseat.gatesvr_id=seat.gatesvr_id
	copyseat.agent_address = seat.agent_address
	copyseat.timeout_fold = seat.timeout_fold
	copyseat.is_tuoguan = seat.is_tuoguan 
	copyseat.playerinfo = {}
	copyseat.playerinfo.rolename=seat.playerinfo.rolename
	copyseat.playerinfo.logo=seat.playerinfo.logo
	copyseat.playerinfo.sex=seat.playerinfo.sex
end

function RoomGameLogic.recovery_gameseat( seat,copyseat )
	seat.state = copyseat.state
	seat.timeout_count = copyseat.timeout_count
	seat.win = copyseat.win
	
	--seat.cards = {}
	
	
	seat.coin = copyseat.coin
	seat.seecards = copyseat.seecards
	seat.autocall = copyseat.autocall
	seat.cards = copyseat.cards
	seat.rid = copyseat.rid
	seat.gatesvr_id=copyseat.gatesvr_id
	seat.agent_address = copyseat.agent_address
	seat.timeout_fold = copyseat.timeout_fold
	seat.is_tuoguan = copyseat.is_tuoguan 

	seat.playerinfo.rolename=copyseat.playerinfo.rolename
	seat.playerinfo.logo=copyseat.playerinfo.logo
	seat.playerinfo.sex=copyseat.playerinfo.sex
end

function RoomGameLogic.onegamestart_inittable(gameobj)
	local tableobj = gameobj.tableobj
	tableobj.action_seat_index = 0
	tableobj.action_to_time = 0
	tableobj.action_type = 0
	tableobj.brand_level = 0
	tableobj.action_cards = nil
	tableobj.cur_bets = tableobj.conf.base_coin  --当前下注
	tableobj.all_bets = 0
	tableobj.rush_seat_index = 0  --开始血拼的玩家座位
	tableobj.rush_bets = 0 --开始血拼前的赌注
	tableobj.turns = 0   --当前游戏圈数
	tableobj.turns_startindex = 0   --计算圈数开始的座位索引
	tableobj.end_delete = 0  --牌局结束需要删除
	tableobj.playernum = 0
	if tableobj.timer_id >= 0 then
		timer.cleartimer(tableobj.timer_id)
		tableobj.timer_id = -1
	end	
end

function RoomGameLogic.recovery_gametable( gameobj,gametable )
	local tableobj = gameobj.tableobj
	tableobj.id = gametable.id
	tableobj.state = gametable.state
	tableobj.action_seat_index = gametable.action_seat_index
	tableobj.action_to_time = gametable.action_to_time
	tableobj.action_type = gametable.action_type
	
	
	tableobj.cur_bets = gametable.cur_bets
	tableobj.all_bets = gametable.all_bets
	tableobj.rush_seat_index = gametable.rush_seat_index
	tableobj.rush_bets = gametable.rush_bets
	tableobj.turns =gametable.turns
	tableobj.turns_startindex = gametable.turns_startindex
	tableobj.end_delete = gametable.end_delete
	tableobj.playernum = gametable.playernum
	tableobj.makers = gametable.makers
	tableobj.delete_table_timer_id = gametable.delete_table_timer_id 
	tableobj.timer_id = gametable.timer_id
	tableobj.sitdown_player_num = gametable.sitdown_player_num

       	local seatinfo
	for index, seat in pairs(gametable.seats) do
	      RoomGameLogic.recovery_gameseat(tableobj.seats[index],seat)
	end

	local doactionntcmsg = {
		rid = tableobj.seats[tableobj.action_seat_index].rid,
		roomsvr_seat_index = tableobj.action_seat_index,
		action_to_time = tableobj.action_to_time,
		game_turns = tableobj.turns,
	}
	
	if tableobj.timer_id >= 0 then
		timer.cleartimer(tableobj.timer_id)
		tableobj.timer_id = -1
		tableobj.timer_id = timer.settimer(tableobj.conf.action_timeout*100, "doaction", doactionntcmsg)
	end
end


function RoomGameLogic.copy_gametable( gameobj,gametable )
	local tableobj = gameobj.tableobj
	gametable.id = tableobj.id
	gametable.name = tableobj.name
	gametable.state = tableobj.state
	gametable.action_seat_index = tableobj.action_seat_index
	gametable.action_to_time = tableobj.action_to_time
	gametable.action_type = tableobj.action_type
	gametable.cur_bets = tableobj.cur_bets
	gametable.all_bets = tableobj.all_bets
	gametable.rush_seat_index = tableobj.rush_seat_index
	gametable.rush_bets = tableobj.rush_bets
	gametable.turns =tableobj.turns
	gametable.turns_startindex = tableobj.turns_startindex
	gametable.end_delete = tableobj.end_delete
	gametable.playernum = tableobj.playernum
	gametable.makers = tableobj.makers
	gametable.timer_id = tableobj.timer_id
	gametable.delete_table_timer_id = tableobj.delete_table_timer_id
	gametable.sitdown_player_num = tableobj.sitdown_player_num
             gametable.room_type = tableobj.conf.room_type
              gametable.game_type = tableobj.conf.game_type
	

	gametable.seats = {}
       	local seatinfo
	for index, seat in pairs(tableobj.seats) do
	            seatinfo = {}
	            if seat.state > ESeatState.SEAT_STATE_NO_PLAYER then
	            	            	RoomGameLogic.copy_gameseat(seat,seatinfo)
	            	            	gametable.seats[index] = seatinfo
	            	end
	end
end


function RoomGameLogic.standup_clear_seat(gameobj, seat)
	seat.rid = 0
	seat.state = ESeatState.SEAT_STATE_NO_PLAYER
	seat.gatesvr_id=""
	seat.agent_address = -1
	seat.playerinfo.rolename = ""
	seat.playerinfo.logo=""
	seat.playerinfo.sex=0
	seat.is_tuoguan = EBOOL.FALSE
	seat.is_robot = false
	seat.timeout_count = 0
	seat.win = EComPareResult.WIN_RESULT_UNKNOW
	seat.cards = {}
	--seat.coin = 0--玩家携带进桌的金币
	seat.is_ready = EBOOL.FALSE
	seat.seecards = 0
	seat.autocall = 0   
end


return RoomGameLogic
