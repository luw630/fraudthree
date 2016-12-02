local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "agenthelper"
local playerdatadao = require "playerdatadao"
local table = table
require "enum"

local  Playergameresult = {}


-- -------------------------------------------------------xj--------------

-- ----------------------------------------------------xj-------------------

function  Playergameresult.process(session, source, fd, request)
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS
	}
	local server = msghelper:get_server()

	--检查当前登陆状态
	if not msghelper:is_login_success() then
		filelog.sys_warning("Playergameresult.process invalid server state", server.state)
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效的请求!"
		msghelper:send_resmsgto_client(fd, "PlayerGameResultRes ", responsemsg)		
		return
	end

	if not msghelper:is_login_success() then
		return
	end
	
	--//多条件查询
	---xj--增量式--
	local SeachNum = request.seachnum --请求战绩次数，每滚动一次加1，
 	local seachstart = SeachNum * 15
 	--xj--增量式--

 	--local timestart = os.date("%Y-%m").."-01 00:00:00"
	--local timeend =  os.date("%Y-%m").."-28 00:00:00"
	--local rid = 1000739--request.rid
	--local condition = "select * from role_resultinfos where((create_time between UNIX_TIMESTAMP('"..timestart.."') and UNIX_TIMESTAMP('"..timeend.."')) and (rid="..rid.."));" --时间格式2016-11-16 19:00:00
	local condition = "select * from role_resultinfos where rid = '" ..request.rid.. "'order by update_time desc limit "..seachstart..",15"  --此句子
	status, info = playerdatadao.query_player_gameresult(request.rid, condition)--获取每局游戏结果，用我的playerID
	
	filelog.sys_error("--------------xxxxx--------",status,"info",info)
-- 	[
--	message GameRusltinfo{
-- 	optional int32 rid;
-- 	optional string creator_name;
-- 	optional int32 room_type;
-- 	optional int32 create_time;
-- 	optional string players_name_coin_winlose;
-- }
-- ]
	-- rid = info.rid
	-- creator_name = info.creator_name
	-- room_type = info.room_type
	-- create_time = info.create_time
	-- players_name_coin_winlose = info.players_name_coin_winlose

	responsemsg.gameresultinfo = {}
	for k,v in pairs(info) do	
		local base = {
		rid = v.rid,
		creator_name = v.creator_name,
		room_type = v.room_type,
		create_time = v.create_time,
		players_name_coin_winlose = v.players_name_coin_winlose,
		}

		table.insert(responsemsg.gameresultinfo, base)
	end
	----msghelper:copy_base_info(responsemsg.gameresultinfo, rid, creator_name, room_type, create_time, players_name_coin_winlose)
	msghelper:send_resmsgto_client(fd, "PlayerGameResultRes", responsemsg)
end

return Playergameresult