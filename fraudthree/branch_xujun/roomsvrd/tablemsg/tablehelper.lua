local skynet = require "skynet"
local filelog = require "filelog"
local msgproxy = require "msgproxy"
local configdao = require "configdao"
local base = require "base"
local tabletool = require "tabletool"
local timetool = require "timetool"
local helperbase = require "helperbase"
local logicmng = require "logicmng"
local playerdataDAO = require "playerdatadao"
require "enum"

local TablesvrHelper = helperbase:new({
    writelog_tables = nil,
    })

function TablesvrHelper:sendmsg_to_alltableplayer(msgname, msg, ...)
    local table_data = self.server.table_data
    --通知座位上的玩家
    for _, seat in ipairs(table_data.seats) do
        if seat.state ~= ESeatState.SEAT_STATE_NO_PLAYER and seat.gatesvr_id ~= "" then
            --filelog.sys_protomsg(msgname..":"..seat.rid, "____"..skynet.self().."_game_notice_____", msg)
            msgproxy.sendrpc_noticemsgto_gatesvrd(seat.gatesvr_id,seat.agent_address, msgname, msg, ...)
        end
    end
    --通知旁观玩家
    for rid, wait in pairs(table_data.waits) do
        --filelog.sys_protomsg(msgname..":"..rid, "____"..skynet.self().."_game_notice_____", msg)
        if wait.gatesvr_id ~= "" then
            msgproxy.sendrpc_noticemsgto_gatesvrd(wait.gatesvr_id, wait.agent_address, msgname, msg, ...)
        end
    end
end

function TablesvrHelper:sendmsg_to_tableplayer(seat, msgname, ...)
    if seat.state ~= ESeatState.SEAT_STATE_NO_PLAYER and seat.gatesvr_id ~= "" then
        msgproxy.sendrpc_noticemsgto_gatesvrd(seat.gatesvr_id,seat.agent_address, msgname, ...)
    end
end

function TablesvrHelper:sendmsg_to_waitplayer(wait, msgname, ...)
    if wait.gatesvr_id ~= "" then
        msgproxy.sendrpc_noticemsgto_gatesvrd(wait.gatesvr_id, wait.agent_address, msgname, ...)
    end
end

--[[
message SeatInfo {
    optional int32 rid = 1;
    optional int32 index = 2;
    optional int32 state = 3;
    optional int32 is_tuoguan = 4; //1表示是 2表示否
    optional int32 coin = 5;  //金币
}

message TablePlayerInfo {
    optional int32 rid = 1;
    optional string rolename = 2;
    optional string logo = 3;
    optional int32 sex = 4;
}

message GameInfo {
    optional int32 id = 1;    //table id
    optional int32 state = 2; //table state
    optional string name = 3; //桌子名字
    optional int32 room_type = 4; //房间类型
    optional int32 game_type = 5; //游戏类型
    optional int32 max_player_num = 6;   //房间支持的最大人数
    optional int32 cur_player_num = 7;   //状态服务器
    optional int32 retain_to_time = 8;   //桌子保留到的时间(linux时间擢)
    optional int32 create_user_rid = 9;  //创建者rid
    optional string create_user_rolename = 10; //创建者姓名
    optional int32 create_time = 11;           //桌子的创建时间
    optional string create_table_id = 12;      //创建桌子的索引id  
    optional string create_user_logo = 13;
    optional string roomsvr_id = 14;           //房间服务器id
    optional int32 roomsvr_table_address = 15; //桌子table的地址
    optional int32 brand_level = 16;           //牌级
    optional int32 min_carry_coin = 17;        //最小携带金币 
    optional int32 base_coin = 18;            //底注
    optional int32 action_timeout = 19;       //玩家操作限时
    optional int32 action_timeout_count = 20; //玩家可操作超时次数   

    optional int32 action_seat_index = 21;    //当前操作玩家的座位号
    optional int32 action_to_time = 22;       //当前操作玩家的到期时间

    //下面两个结构按数组下标一一对应
    repeated SeatInfo seats = 23; //座位
    repeated TablePlayerInfo tableplayerinfos = 24;

    optional int32 the_round = 25;               //记录当前是第几轮
    optional int32 game_turns= 26;               //记录当前第几圈
    optional int32 force_overturns= 27;                  //强制结束的圈数
}

]]

function TablesvrHelper:copy_table_gameinfo(gameinfo)
    local table_data = self.server.table_data
    gameinfo.id = table_data.id
    gameinfo.state = table_data.state
    gameinfo.name = table_data.conf.name
    gameinfo.room_type = table_data.conf.room_type
    gameinfo.game_type = table_data.conf.game_type
    gameinfo.max_player_num = table_data.conf.max_player_num
    gameinfo.cur_player_num = table_data.conf.cur_player_num
    gameinfo.retain_to_time = table_data.retain_to_time
    gameinfo.create_user_rid = table_data.conf.create_user_rid
    gameinfo.create_user_rolename = table_data.conf.create_user_rolename
    gameinfo.create_time = table_data.conf.create_time
    gameinfo.create_table_id = table_data.conf.create_table_id
    gameinfo.action_timeout = table_data.conf.action_timeout
    gameinfo.action_timeout_count = table_data.conf.action_timeout_count           
    gameinfo.create_user_logo = table_data.conf.create_user_logo
    gameinfo.roomsvr_id = table_data.svr_id
    gameinfo.roomsvr_table_address = skynet.self()        
    gameinfo.min_carry_coin = table_data.conf.min_carry_coin 
    gameinfo.base_coin = table_data.conf.base_coin

    gameinfo.action_seat_index = table_data.action_seat_index
    gameinfo.action_to_time = table_data.action_to_time
    gameinfo.the_round = table_data.the_round
    gameinfo.game_turns = table_data.turns
    gameinfo.force_overturns = table_data.conf.force_overturns
    --TO ADD添加牌信息

    gameinfo.seats = {}
    gameinfo.tableplayerinfos = {}
    local seatinfo, tableplayerinfo
    for index, seat in pairs(table_data.seats) do
        seatinfo = {}
        tableplayerinfo = {}
        self:copy_seatinfo(seatinfo, seat)
        table.insert(gameinfo.seats, seatinfo)
        self:copy_tableplayerinfo(tableplayerinfo, seat)
        table.insert(gameinfo.tableplayerinfos, tableplayerinfo)
    end

end

function TablesvrHelper:copy_seatinfo(seatinfo, seat)
    seatinfo.rid = seat.rid
    seatinfo.index = seat.index
    seatinfo.state = seat.state
    seatinfo.is_tuoguan = seat.is_tuoguan
    seatinfo.coin = seat.coin
    seatinfo.team = seat.team
    seatinfo.cardsnum = #(seat.cards)
    seatinfo.rank = seat.rank
    seatinfo.seecards = seat.seecards    --是否看牌
    seatinfo.autocall = seat.autocall    --是否自动跟注
end

function TablesvrHelper:copy_tableplayerinfo(tableplayerinfo, seat)
    tableplayerinfo.rid = seat.rid
    tableplayerinfo.rolename = seat.playerinfo.rolename
    tableplayerinfo.logo = seat.playerinfo.logo
    tableplayerinfo.sex = seat.playerinfo.sex
end

function TablesvrHelper:copy_playergameendinfo(playerinfos)
    local table_data = self.server.table_data
    for index, seat in pairs(table_data.seats) do
        playerinfos[#playerinfos + 1] = {
            rid = seat.rid,
            allcoin = seat.coin,
            getcoin = seat.getcoin,
            rank = seat.rank,
        }
    end
end

--用于输出指定table_id桌子的信息，方便定位问题
function TablesvrHelper:write_tableinfo_log(...)
    if self.writelog_tables == nil then
        self.writelog_tables = configdao.get_common_conf("tables")
    end

    if self.writelog_tables == nil then
        return
    end
    if self.writelog_tables[self.server.table_data.id] ~= nil then
        filelog.sys_obj("table", self.server.table_data.id, ...)           
    end 
end

--记录调试日志
function TablesvrHelper:write_debug_log(classname, objname, ...)
    if base.isdebug() then
        filelog.sys_obj(classname, objname, ...)
    end
end

function TablesvrHelper:report_table_state()
    local table_data = self.server.table_data
    --上报table
    local table_state = {
        id = table_data.id,
        state = table_data.state,
        cur_player_num = table_data.sitdown_player_num,
        retain_to_time = table_data.retain_to_time,

        name = table_data.conf.name,
        create_user_rid = table_data.conf.create_user_rid,
        create_user_rolename = table_data.conf.create_user_rolename,
        create_user_logo = table_data.conf.create_user_logo,
        create_time = table_data.conf.create_time,
        create_table_id = table_data.conf.create_table_id,
        action_timeout = table_data.conf.action_timeout,
        action_timeout_count = table_data.conf.action_timeout_count,           
        room_type = table_data.conf.room_type,
        game_type = table_data.conf.game_type,
        max_player_num = table_data.conf.max_player_num,
        brand_level = table_data.conf.brand_level,
        min_carry_coin = table_data.conf.min_carry_coin,
        base_coin = table_data.conf.base_coin,

        roomsvr_id = table_data.svr_id,
        roomsvr_table_address = skynet.self(),        
    }
    msgproxy.sendrpc_broadcastmsgto_tablesvrd("update", table_data.svr_id, table_state)
end

function TablesvrHelper:get_game_logic()
    local table_data = self.server.table_data
    if table_data.conf.room_type == ERoomType.ROOM_TYPE_FRIEND_COMMON then
           return logicmng.get_logicbyname("roomfndgamelogic")
        -- return logicmng.get_logicbyname("roomgamelogic")
    elseif table_data.conf.room_type == ERoomType.ROOM_TYPE_COMMON then
        return logicmng.get_logicbyname("roomgamelogic")
    end
end

---------------------------------------xj-----------
function TablesvrHelper:DBinsert_player_game_result(tableoj)
   
   local record_sit_seat = tableoj.conf.start_game_player_info   --{同桌rid,同桌名字}
   local creator_name = tableoj.conf.create_user_rolename        --创建者的名字
   local rid = tableoj.create_user_rid                     --创建者rid
   local creat_time = tableoj.conf.create_time            --创建时间
   local coin_realize = tableoj.conf.coin_realize --获取烙有rid的金币包{rid=money}
   local room_type = tableoj.conf.room_type
   
   -- filelog.sys_info("房间名字：", creator_name )
   -- filelog.sys_info("创建时间：", creat_time)
   -- filelog.sys_info("房间类型：", room_type)
    for i, v in pairs(record_sit_seat) do
        if coin_realize[v.rid] ~= nil then
            v.win_lose =  coin_realize[v.rid]
        else
            v.win_lose =  0
        end
    end

--  [
--  message GameRusltinfo{
--  optional int32 rid;
--  optional string creator_name;
--  optional int32 room_type;
--  optional int32 create_time;
--  optional string players_name_coin_winlose;
-- }
-- ]

    for i, v in pairs(record_sit_seat) do
        local game_result = {
                rid = v.rid,                                  --查询战绩玩家的rid
                creator_name = creator_name,                              --创建者的名字
                room_type = room_type,                                      --房间类型（朋友桌 2）
                create_time = creat_time,                                 --房间创建时间
                players_name_coin_winlose = nil,                            --改玩家和哪些人在某局下过注
            }
        game_result.players_name_coin_winlose = record_sit_seat     
        playerdataDAO.save_player_game_result("insert", game_result.rid, game_result)
    end

end
---------------------------------------xj-----------
return  TablesvrHelper