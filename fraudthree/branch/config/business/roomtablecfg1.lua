table_conf_list_1 = {
    begin_id = 10100,
    num  = 50,    
    conf = {
        version = 1,
        room_type = 1,             --桌子的房间类型
        game_type = 1,
        min_player_num = 2,        --最少开始游戏人数
        max_player_num = 9,        --桌子座位数
        min_carry_coin = 200,   --最小携带金币
        max_carry_coin = 2000,
        name = "练习场",
        max_wait_num = 300,         --最大旁观人数
        action_timeout = 15,      --玩家操作超时时间单位s
        action_timeout_count = -1,  --连续超时判定次数
        base_coin = 10,              --底分
        brand_level = 0,            --牌级    
        ready_timeout = 30,   
        tuoguan_timeout_count = 2,  --托管超时次数   
        realend_timeout = 3,        --client结算动画时间
        back_timeout = 15,          --还牌超时时间
        force_overturns = 5,        --强制比牌的游戏圈数
    }
}


table_conf_list_2 = {
    begin_id   = 10200,
    num  = 50,    
    conf = {
        version = 1,
        room_type = 1,           --桌子的房间类型
        game_type = 2,
        min_player_num = 2,      --最少开始游戏人数
        max_player_num = 9,      --桌子座位数
        min_carry_coin = 2000,
        max_carry_coin = 2000,
        name = "新手场",
        max_wait_num = 300,         --最大旁观人数
        action_timeout = 15,        --玩家操作超时时间单位s
        action_timeout_count = -1,  --连续超时判定次数
        base_coin = 100,              --底分
        brand_level = 0,            --牌级
        ready_timeout = 30,   
        tuoguan_timeout_count = 2,  --托管超时次数   
        realend_timeout = 3,        --client结算动画时间
        back_timeout = 15,          --还牌超时时间
        force_overturns = 5,        --强制比牌的游戏圈数
    }
}

table_conf_list_3 = {
    begin_id  = 10300,
    num  = 50,    
    conf = {
        version = 1,
        room_type = 1,           --桌子的房间类型
        game_type = 3,
        min_player_num = 2,      --最少开始游戏人数
        max_player_num = 9,      --桌子座位数
        min_carry_coin = 20000,
        max_carry_coin = 2000,
        name = "高级场",
        max_wait_num = 300,         --最大旁观人数
        action_timeout = 15,      --玩家操作超时时间单位s
        action_timeout_count = -1,  --连续超时判定次数
        base_coin = 1000,      --底分
        brand_level = 0,            --牌级
        ready_timeout = 30,   
        tuoguan_timeout_count = 2,  --托管超时次数   
        realend_timeout = 3,        --client结算动画时间
        back_timeout = 15,          --还牌超时时间
        force_overturns = 5,        --强制比牌的游戏圈数
    }
}

table_conf_list_4 = {
    begin_id  = 10400,
    num  = 50,    
    conf = {
        version = 1,
        room_type = 1,           --桌子的房间类型
        game_type = 4,
        min_player_num = 2,      --最少开始游戏人数
        max_player_num = 9,      --桌子座位数
        min_carry_coin = 200000,
        max_carry_coin = 2000,
        name = "大师场",
        max_wait_num = 300,         --最大旁观人数
        action_timeout = 15,      --玩家操作超时时间单位s
        action_timeout_count = -1,  --连续超时判定次数
        base_coin = 10000,              --底分
        brand_level = 0,            --牌级
        ready_timeout = 30,   
        tuoguan_timeout_count = 2,  --托管超时次数   
        realend_timeout = 3,        --client结算动画时间
        back_timeout = 15,          --还牌超时时间
        force_overturns = 5,        --强制比牌的游戏圈数
    }
}