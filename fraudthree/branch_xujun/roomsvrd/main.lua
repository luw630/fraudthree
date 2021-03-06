local skynet = require "skynet"
local filelog = require "filelog"
local configdao = require "configdao"

skynet.start(function()
    print("Server start")
    skynet.newservice("systemlog")
    local confcentersvr = skynet.newservice("confcenter")
    skynet.call(confcentersvr, "lua", "start")
    print("confcenter start success")

--     roomsvrs={
--     roomsvr_1={
--         tablesize=1000,
--         tableinrc=200,
--         timersize = 1000,
--         debug_console_port = 8011,
--     },
-- }

    local roomsvrs = configdao.get_svrs("roomsvrs")
    if roomsvrs == nil then
        print("roomsvrd start failed roomsvrs == nil")
        skynet.exit()
    end

    -- svr_id = "roomsvr_1"

    local roomsvr = roomsvrs[skynet.getenv("svr_id")]
    if roomsvr == nil then
        print("roomsvrd start failed roomsvr == nil", skynet.getenv("svr_id"))
        skynet.exit()           
    end

    local proxys = configdao.get_svrs("proxys")
    if proxys ~= nil then
        for id, conf in pairs(proxys) do
            local svr = skynet.uniqueservice("proxy", id)
            conf.svr_id = skynet.getenv("svr_id")
            skynet.call(svr, "lua", "init", conf)            
        end 
    end

    local timersvr = skynet.newservice("timercenter")
    skynet.call(timersvr, "lua", "init", roomsvr.timersize)

    skynet.newservice("debug_console", roomsvr.debug_console_port)
    
    --[[local mongologs = configdao.get_svrs("mongologs")
    if mongologs ~= nil then
        for id, conf in pairs(mongologs) do
            local svr = skynet.newservice("mongolog", id)
            skynet.call(svr, "lua", "init", conf)            
        end
    end]]
    
    local params = ",,,,,"..skynet.getenv("svr_id")   ----,,,,,roomsvr_1
    local watchdog = skynet.newservice("roomsvrd", params)
    skynet.call(watchdog, "lua", "cmd", "start", roomsvr)
    -- skynet.call(watchdog, "lua", "cmd", "start", {
    --     port = roomsvr.svr_port,
    --     maxclient = roomsvr.maxclient,
    --     nodelay = true,
    --     agentsize = roomsvr.agentsize,
    --     agentincr = roomsvr.agentincr,
    --     svr_netpack = roomsvr.svr_netpack,
    --     redisconn = roomsvr.redisconn,
    -- })
    print("roomsvrd start success ")
    skynet.exit()   
end)
