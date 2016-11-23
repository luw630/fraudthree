EErrCode = {
	ERR_SUCCESS            = 0,   --成功
	ERR_ACCESSDATA_FAILED  = 2,   --访问数据失败
	ERR_INVALID_REQUEST    = 3,   --无效的请求
	ERR_VERIFYTOKEN_FAILED = 4,   --验证token失败
	ERR_NOGATESVR = 5, --当前无可用的服务器
	ERR_INVALID_PARAMS = 6, --无效的参数
	ERR_NET_EXCEPTION = 7,  --错误的网络异常
	ERR_SYSTEM_ERROR = 8,   --系统错误
	ERR_SERVER_EXPIRED = 9, --服务器过期
	ERR_DEADING_LASTREQ = 10, --正在处理上一次请求
	ERR_CREATE_TABLE_FAILED = 11, --创建朋友桌失败
	ERR_HAD_IN_TABLE = 12, --已经在桌在内
	ERR_HAD_IN_SEAT = 13, --已经在座位上
	ERR_TABLE_FULL = 14, --桌子已经满了
	ERR_NO_EMPTY_SEAT = 15, --桌子已经没有空座位
	ERR_HAD_STANDUP = 16, --已经站起来了
	ERR_NOT_INTABLE = 17, --玩家不在座位上
	ERR_CANNOT_MOVE = 18, --此位置不能落子
	ERR_NOTENOUGH_COIN = 19, --没有足够的金币
	ERR_INVALID_CREATETABLEID = 20, --无效的桌号
	ERR_INVALID_ROOMTYPE = 21, --无效的场次类型
	ERR_INVALID_GAMETYPE = 22, --无效的游戏类型
	ERR_NO_VALID_TABLE = 23,   --当前无可用的房间
	ERR_PLAYER_OFFLINE = 24, --桌主离线
	ERR_PLAYER_AGREE= 25, --桌主同意
	ERR_PLAYER_REFUSE= 26, --桌主拒绝
	ERR_PLAYER_LEAVE= 27, --玩家已经离开
}

--agent的状态
EGateAgentState = {
	GATE_AGENTSTATE_UNKNOW = 0,    --初始状态
	GATE_AGENTSTATE_LOGINING = 1,  --正在登陆
	GATE_AGENTSTATE_LOGINED = 2,   --登陆成功
	GATE_AGENTSTATE_LOGOUTING = 3, --正在登出
	GATE_AGENTSTATE_LOGOUTED = 4,  --退出成功
}
--bool的枚举值定义
EBOOL = {
	FALSE = 0,
	TRUE = 1,
}

--分组类型
ETeam = {
	TEAM_UNKNOW = 0,
	TEAM_A = 1,  --A组
	TEAM_B = 2,  --B组 
} 
--桌子的状态
ETableState = {
	TABLE_STATE_UNKNOW = 0,
	TABLE_STATE_WAIT_MIN_PLAYER = 1,        --等待最小玩家数
	TABLE_STATE_WAIT_ALL_READY = 2,			--等待所有玩家准备好
	TABLE_STATE_WAIT_GAME_START = 3,        --等待桌主开始游戏
	TABLE_STATE_WAIT_CLIENT_ACTION = 4,     --等待client操作
	TABLE_STATE_WAIT_CLIENT_ACTION_PLAY = 7,    --等待出牌
	TABLE_STATE_WAIT_ONE_GAME_REAL_END = 8, --等待一局游戏真正结束
	TABLE_STATE_WAIT_GAME_END = 9,      --等待游戏结束
	TABLE_STATE_GAME_START = 10,        --游戏开始状态
	TABLE_STATE_ONE_GAME_START = 11,    --一局游戏开始
	TABLE_STATE_CONTINUE = 12,
	TABLE_STATE_CONTINUE_AND_STANDUP = 13,
	TABLE_STATE_CONTINUE_AND_LEAVE = 14,
	TABLE_STATE_ONE_GAME_END = 15,      --一局游戏结束
	TABLE_STATE_ONE_GAME_REAL_END = 16, --一局游戏真正结束 
	TABLE_STATE_GAME_END = 17,  	    --游戏结束
	TABLE_STATE_SHOW_TIME = 18,  	    --玩家SHOW牌
}

--座位状态
ESeatState = {
	SEAT_STATE_UNKNOW = 0,
	SEAT_STATE_NO_PLAYER = 1,  --没有玩家
	SEAT_STATE_WAIT_START = 2, --等待开局
	SEAT_STATE_STANDUP = 3,    --站起
	SEAT_STATE_ESCAPE = 4, 		--逃跑
	SEAT_STATE_PLAYING  = 5,   --正在游戏中
	SEAT_STATE_CALL = 6,       --跟注
	SEAT_STATE_RAISE = 7,		--加注
	SEAT_STATE_RUSH = 8,		--血拼
	SEAT_STATE_FOLD = 9,       --弃牌
	SEAT_STATE_LOSE = 10,     --比牌后等待下局游戏
}

--单独的玩家操作类型,无需轮到玩家才能操作
EAloneActionType = 
{
	AloneAction_UNKNOW = 0,
	AloneAction_SEECARDS = 1,--看牌
	AloneAction_AUTOCALL = 2,--自动跟注
	AloneAction_FOLD = 3,--弃牌
}

--玩家操作类型
EActionType = {
	ACTION_TYPE_UNKNOW = 0,
	ACTION_TYPE_STANDUP = 1,
	ACTION_TYPE_TIMEOUT = 2,
	ACTION_TYPE_CALL = 3,--跟注
	ACTION_TYPE_RAISE = 4,--加注
	ACTION_TYPE_COMPARE = 5,--比牌
	ACTION_TYPE_RUSH = 6,--血拼
	ACTION_TYPE_FORCECOMPARE = 7,--强制比牌
	ACTION_TYPE_SEECARDS = 10,--看牌
	ACTION_TYPE_AUTOCALL = 11,--自动跟注
	ACTION_TYPE_FOLD = 12,--弃牌
	ACTION_TYPE_SHOWCARD = 13,--SHOW牌
}

--房间类型
ERoomType = {
	ROOM_TYPE_UNKNOW = 0,
	ROOM_TYPE_COMMON = 1, --普通游戏
	ROOM_TYPE_FRIEND_COMMON = 2, --自建朋友桌
}

--游戏类型
EGameType = {
	GAME_TYPE_UNKNOW = 0,
	GAME_TYPE_PRACTICE = 1, --练习场
	GAME_TYPE_NEW = 2,    --新手场
	GAME_TYPE_SENIOR = 3, --高级场
	GAME_TYPE_MASTER = 4, --大师场
	GAME_TYPE_COMMON = 5, 
}

--游戏开始的触发类型
EGameStartType = {
	GAME_START_BYUNKNOW = 0,
	GAME_START_BYPLAYER = 1,   --玩家发送的游戏开始
	GAME_START_BYSERVER = 2, --由服务器的定时器触发
}

--发行平台
EPublishPlatform = {
	PUBLISH_PLATFORM_JUZONG = 1, --聚众
	PUBLISH_PLATFORM_COMMON = 100, --通用平台
}
--发行渠道
EPublishChannel = {
	PUBLISH_CHANNEL_JUZONG_IOS = 1, --聚众ios官方渠道
	PUBLISH_CHANNEL_JUZONG_ANDROID = 2, --聚众android官方渠道
	PUBLISH_CHANNEL_COMMON = 1000,  --通用渠道
}

--玩家站起原因
EStandupReason = {
	STANDUP_REASON_UNKNOW = 0,
	STANDUP_REASON_ONSTANDUP = 1, --玩家主动站起
	STANDUP_REASON_TIMEOUT_STANDUP = 2, --准备超时站起
	STANDUP_REASON_MONEYNOTENOUGH =3, --金币不足
	STANDUP_REASON_TABLEDELETE =4, --房间需要删除
}


EComPareResult = {  			--比牌结果
	WIN_RESULT_UNKNOW = 0,
	WIN_RESULT_WIN = 1,
	WIN_RESULT_LOSE = 2,
	WIN_RESULT_DRAW = 3 ,
}

EGameRank = 
{
    GAME_RANK_1 = 1,
    GAME_RANK_2 = 2,
    GAME_RANK_3 = 3,
    GAME_RANK_4 = 4
}

ESendMailReasonType = {
	COMMON_TYPE_TESTING = 1, ---测试邮件
	COMMON_TYPE_MOVING = 2, ---活动邮件
}

---游戏中的货币类型
ECurrencyType = {
	CURRENCY_TYPE_UNKNOWN = 0,
	CURRENCY_TYPE_COIN = 1,
}

---货币变化的原因
EReasonChangeCurrency = {
	CHANGE_CURRENCY_UNKNOWN = 0,
	CHANGE_CURRENCY_SYSTEM_GAME = 1, --系统桌结算
	CHANGE_CURRENCY_FRIEND_TABLE =2, --朋友桌结算
	CHANGE_CURRENCY_RECHARGE = 3, --商城充值
	CHANGE_CURRENCY_GETITEM_FROM_MAIL = 4, ---领取邮件附件
}