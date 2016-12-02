local skynet = require "skynet"
local filelog = require "filelog"
local configdao = require "configdao"
--local msgproxy = require "msgproxy"
local timetool = require "timetool"
local helperbase = require "helperbase"
local playerdatadao = require "playerdatadao"
local gamelog = require "gamelog"
local base = require "base"
require "enum"

local trace_rids = nil
local AgentHelper = helperbase:new({}) 

--用于输出指定rid玩家的信息，方便定位问题
function AgentHelper:write_agentinfo_log(...)
	if trace_rids == nil then
		trace_rids = configdao.get_common_conf("rids")
	end

	if trace_rids == nil then
		return
	end

	local rid = self.server.rid
	if (trace_rids.isall ~= nil and trace_rids.isall) or trace_rids[rid] ~= nil then
		filelog.sys_obj("agent", rid, ...)	
	end	
end

--用于copy玩家的基本信息
function AgentHelper:copy_base_info(baseinfo, info, playgame, money)
	baseinfo.rid = info.rid
	baseinfo.rolename = info.rolename
    baseinfo.logo = info.logo
    baseinfo.phone = info.phone
    baseinfo.coin = money.coin
    baseinfo.maxcoin = money.maxcoin
    baseinfo.winnum = playgame.winnum 
    baseinfo.losenum = playgame.losenum
    baseinfo.sex = info.sex
    baseinfo.continuewinnum = playgame.continuewinnum
end

--判断玩家是否登陆成功
function AgentHelper:is_login_success()
	return  (self.server.state == EGateAgentState.GATE_AGENTSTATE_LOGINED) 
end

--判断玩家是否退出成功
function AgentHelper:is_logout_success()
	return  (self.server.state == EGateAgentState.GATE_AGENTSTATE_LOGOUTED) 
end

function AgentHelper:save_player_coin(rid,number,reason)
	local money = self.server.money
	local beforetotal = money.coin
	local aftertotal = 0
	if money.coin + number >= 0 then
		money.coin = money.coin + number
		if money.coin > money.maxcoin then money.maxcoin = money.coin end
	else
		money.coin = 0
	end
	aftertotal = money.coin
	playerdatadao.save_player_money("update",rid,self.server.money)
	--gamelog.write_player_coinlog(rid, reason, ECurrencyType.CURRENCY_TYPE_COIN, number, beforetotal, aftertotal)
end
----playgame中的字段做增量更新
function AgentHelper:save_player_gameInfo(rid,noticemsg,reason)
	local playgame = self.server.playgame
	---TO ADD 保存数据
	if noticemsg.isendgame > 0 then
		if playgame.winnum == nil then
			filelog.sys_info("AgentNotice.gameresult",playgame)
		end
		playgame.winnum = playgame.winnum + 1
		playgame.laststatus = playgame.laststatus + 1
	else
		if playgame.losenum == nil then
			filelog.sys_info("AgentNotice.gameresult",playgame)
		end
		playgame.losenum = playgame.losenum + 1
		playgame.laststatus = 0
	end

	if playgame.laststatus > playgame.continuewinnum then
		playgame.continuewinnum  = playgame.laststatus
	end
	playerdatadao.save_player_playgame("update",rid,self.server.playgame)
end

function AgentHelper:save_player_awards(rid, awards, reason)
	if awards == nil then
		return
	end

	for _, award in ipairs(awards) do
		if award.id == ECurrencyType.CURRENCY_TYPE_COIN then
			self:save_player_coin(rid, award.num, reason)
		elseif award.id == ECurrencyType.CURRENCY_TYPE_DIAMOND then
			self:save_player_diamond(rid, award.num, reason)
		else
			--TO ADD 操作道具
		end
	end	
end

--- 生成邮件接口
-- @param rid
-- @param mailtable 邮件结构
-- @param reason
--
function AgentHelper:generate_mail(rid,mailtable,reason)
	if not rid or rid <= 0 or type(mailtable) ~= "table" then return end
	mailtable.mail_key = base.generate_uuid()
	mailtable.rid = rid
	mailtable.create_time = timetool.get_time()
	mailtable.reason = reason or ESendMailReasonType.COMMON_TYPE_TESTING
	playerdatadao.save_player_mail("insert",rid,mailtable,nil)
end


return AgentHelper