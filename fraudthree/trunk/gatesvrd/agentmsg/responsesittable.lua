local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "agenthelper"
local msgproxy = require "msgproxy"
local playerdatadao = require "playerdatadao"
local processstate = require "processstate"
local table = table
require "enum"

local processing = processstate:new({timeout=4})
local  ResponseSitTable = {}

--[[
//桌主回复坐入桌子请求
message ResponseSitTableReq {
	optional Version version = 1;
	optional int32 id = 2;
	optional string roomsvr_id = 3; //房间服务器id
	optional int32  roomsvr_table_address = 4; //桌子的服务器地址
	optional int32 isagree = 5;  //1 同意  2 拒绝
}
//响应桌主回复
message ResponseSitTableRes {
	optional int32 errcode = 1; //错误原因 0表示成功
	optional string errcodedes = 2; //错误描述	
}
]]

function  ResponseSitTable.process(session, source, fd, request)
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS,
	}
	local server = msghelper:get_server()

	--检查当前登陆状态
	if not msghelper:is_login_success() then
		filelog.sys_warning("ResponseSitTable.process invalid server state", server.state)
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效的请求！"
		msghelper:send_resmsgto_client(fd, "ResponseSitTableRes", responsemsg)		
		return
	end

	if processing:is_processing() then
		responsemsg.errcode = EErrCode.ERR_DEADING_LASTREQ
		responsemsg.errcodedes = "正在处理上一次请求！"
		msghelper:send_resmsgto_client(fd, "ResponseSitTableRes", responsemsg)		
		return
	end

	if request.isagree == nil then
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效的请求！"
		msghelper:send_resmsgto_client(fd, "ResponseSitTableRes", responsemsg)		
		return
	end

	local bnew,online = playerdatadao.query_player_online(request.quest_rid)
	if online == nil then
		responsemsg.errcode = EErrCode.ERR_PLAYER_OFFLINE
		responsemsg.errcodedes = "申请的玩家已经下线"
		msghelper:send_resmsgto_client(fd, "ResponseSitTableRes", responsemsg)		
		return
	end


	if online.roomsvr_id == "" or online.roomsvr_id ~= request.roomsvr_id then
		responsemsg.errcode = EErrCode.ERR_PLAYER_LEAVE
		responsemsg.errcodedes = "请求玩家已经离开桌子"
		msghelper:send_resmsgto_client(fd, "ResponseSitTableRes", responsemsg)		
		return		
	end

	if online.roomsvr_table_id <= 0 or online.roomsvr_table_id ~= request.id then
		responsemsg.errcode = EErrCode.ERR_PLAYER_LEAVE
		responsemsg.errcodedes = "请求玩家已经离开桌子"
		msghelper:send_resmsgto_client(fd, "ResponseSitTableRes", responsemsg)		
		return		
	end

	if online.roomsvr_table_address ~= request.roomsvr_table_address then
		responsemsg.errcode = EErrCode.ERR_PLAYER_LEAVE
		responsemsg.errcodedes = "请求玩家已经离开桌子"
		msghelper:send_resmsgto_client(fd, "ResponseSitTableRes", responsemsg)		
		return	
	end

-- //桌主回复坐入桌子请求的通知
-- message ResponseSitTableNtc {
-- 	optional int32 id = 1;
-- 	optional int32 isagree = 2;  //1 同意  2 拒绝
-- 	optional string roomsvr_id = 3; //房间服务器id
-- 	optional int32  roomsvr_table_address = 4; //桌子的服务器地址
-- }
	local responsesittable = 
	{
		id = online.roomsvr_table_id,
		isagree = request.isagree,
		roomsvr_id = online.roomsvr_id ,
		roomsvr_table_address = online.roomsvr_table_address,
	}

	if request.isagree == 2 then
		responsesittable.roomsvr_id = ""
		responsesittable.roomsvr_table_address = 0
	end

	processing:set_process_state(true)
	 msgproxy.sendrpc_noticemsgto_gatesvrd(online.gatesvr_id,online.gatesvr_service_address, "ResponseSitTableNtc",responsesittable)
	processing:set_process_state(false)

	if not msghelper:is_login_success() then
		return
	end
	msghelper:send_resmsgto_client(fd, "ResponseSitTableRes", responsemsg)
end

return ResponseSitTable

