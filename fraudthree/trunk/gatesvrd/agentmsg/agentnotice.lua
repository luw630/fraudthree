local filelog = require "filelog"
local msghelper = require "agenthelper"
local playerdatadao = require "playerdatadao"
local base = require "base"
require "enum"

local AgentNotice = {}

function AgentNotice.process(session, source, event, ...)
	local f = AgentNotice[event] 
	if f == nil then
		f = AgentNotice["other"]
		f(event, ...)
		return
	end
	f(...)
end

function AgentNotice.leavetable(noticemsg)
	if not msghelper:is_login_success() then
		return
	end

	local server = msghelper:get_server()
	if server.rid ~= noticemsg.rid then
		return
	end

	if server.roomsvr_id ~= noticemsg.roomsvr_id then
		return
	end

	if server.roomsvr_table_id ~= noticemsg.roomsvr_table_id then
		return
	end

	if server.roomsvr_table_address ~= noticemsg.roomsvr_table_address then
		return
	end

	server.roomsvr_id = ""
	server.roomsvr_table_id = 0
	server.roomsvr_table_address = -1
	server.roomsvr_seat_index = 0
	server.online.roomsvr_id = ""
	server.online.roomsvr_table_id = 0
    server.online.roomsvr_table_address = -1
	playerdatadao.save_player_online("update", server.rid, server.online)

	if noticemsg.is_sendto_client then
		msghelper:send_resmsgto_client(nil, "LeaveTableRes", {errcode = EErrCode.ERR_SUCCESS})		
	end
end

function AgentNotice.standuptable(noticemsg)
	local server = msghelper:get_server()
	if server.rid ~= noticemsg.rid then
		return
	end

	if server.roomsvr_id ~= noticemsg.roomsvr_id then
		return
	end

	if server.roomsvr_table_id ~= noticemsg.roomsvr_table_id then
		return
	end

	if server.roomsvr_seat_index ~= noticemsg.roomsvr_seat_index then
		return
	end
	server.roomsvr_seat_index = 0
end

function AgentNotice.other(msgname, noticemsg)
	msghelper:send_noticemsgto_client(nil, msgname, noticemsg)
end

function AgentNotice.gameresult(noticemsg)
	local server = msghelper:get_server()
	local playgame = server.playgame
	local money = server.money

	

	if server.rid ~= noticemsg.rid then
	     filelog.sys_error("gameresult save_player_money faile",server.rid,noticemsg.rid)
		return
	end

	if noticemsg.isendgame > 0 then
		playgame.winnum = playgame.winnum + 1
		playgame.laststatus = playgame.laststatus + 1
	else
		playgame.losenum = playgame.losenum + 1
		playgame.laststatus = 0
	end

	if playgame.laststatus > playgame.continuewinnum then
		playgame.continuewinnum  = playgame.laststatus
	end
	
	--print("AgentNotice.gameresult rid "..server.rid.."  money  "..noticemsg.win_money)
	server.money.coin = noticemsg.win_money
	if  server.money.coin > server.money.maxcoin then
		server.money.maxcoin = server.money.coin
	end
	playerdatadao.save_player_money("update",server.rid,server.money)
	playerdatadao.save_player_playgame("update",server.rid,server.playgame)
end

function AgentNotice.updateplayerinfo(rid,update_key_value,reason,is_sendto_client)
	local server = msghelper:get_server()
	if server.rid ~= rid or not update_key_value or type(update_key_value) ~= "table" then
		return 
    end
    for key,value in pairs(update_key_value) do
        if key == "money" then
            if type(value) == "table" then
                if value.coin and value.coin ~= 0 then
                    msghelper:save_player_coin(rid,value.coin,reason)
                end
            end
        elseif key == "playgame" then
            if type(value) == "table" then
                msghelper:save_player_gameInfo(rid, value, reason)
            end
        end
    end

    if is_sendto_client == true then
        local responsemsg = {
            baseinfo = {},
        }
        msghelper:copy_base_info(responsemsg.baseinfo, server.info, server.playgame, server.money)
        ---msghelper:send_noticemsgto_client(nil,"PlayerBaseInfoNtc",responsemsg)
    end

end

function AgentNotice.updateplayerinfo(rid,update_key_value,reason,is_sendto_client)
	local server = msghelper:get_server()
	if server.rid ~= rid or not update_key_value or type(update_key_value) ~= "table" then
		return 
    end
    for key,value in pairs(update_key_value) do
        if key == "money" then
            if type(value) == "table" then
                if value.coin and value.coin ~= 0 then
                    msghelper:save_player_coin(rid,value.coin,reason)
                end
            end
        elseif key == "playgame" then
            if type(value) == "table" then
                msghelper:save_player_gameInfo(rid, value, reason)
            end
        end
    end

    if is_sendto_client == true then
        local responsemsg = {
            baseinfo = {},
        }
        msghelper:copy_base_info(responsemsg.baseinfo, server.info, server.playgame, server.money)
        ---msghelper:send_noticemsgto_client(nil,"PlayerBaseInfoNtc",responsemsg)
    end
end

return AgentNotice