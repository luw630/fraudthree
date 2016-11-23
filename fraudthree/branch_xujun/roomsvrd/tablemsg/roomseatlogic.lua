require "enum"
require "cardvalue"
local msghelper = require "tablehelper"
local cardtool = require "cardtool"

local RoomSeatLogic = {}

function RoomSeatLogic.init(seatobj, index)
	seatobj.index = index
	seatobj.state = ESeatState.SEAT_STATE_NO_PLAYER
	seatobj.is_tuoguan = EBOOL.FALSE
	return true
end

function RoomSeatLogic.clear(seatobj)
	seatobj.rid = 0
	seatobj.state = 0  --改坐位玩家状态
	seatobj.gatesvr_id=""
	seatobj.agent_address = -1
	seatobj.playerinfo = {}
end

function RoomSeatLogic.is_empty(seatobj)
	return (seatobj.state == ESeatState.SEAT_STATE_NO_PLAYER)
end

function RoomSeatLogic.CountCardByNum(seatobj,val,num)
	if num > 2 or num < 0 then
		return false;
	end

	local count = 0;
	local cards = seatobj.cards;
	for i=1,#cards do
        if (cards[i].card_laizireplacevalue == val) then
            count = count + 1;
        end
    end

    if (count >= num) then
    	return true;
    end

	return false;
end

-- //玩家座位状态改变
-- message SeatStatusNtc{
-- 	optional int32 rid = 1;
-- 	optional int32 roomsvr_seat_index = 2;
-- 	optional int32 seatstatus = 3;       //座位的状态
-- 	repeated CardInfo playercards = 4; // 玩家的牌
-- }

function RoomSeatLogic.DealCards(seatobj)
	--把牌发给玩家
	local seatstatusntc = {
		rid = seatobj.rid,
		roomsvr_seat_index = seatobj.index,
		seatstatus = seatobj.state,
		--cards = seatobj.cards,
	}
	if seatobj.seecards ~= nil and seatobj.seecards > 0 then
		seatstatusntc.seatstatus = seatstatusntc.seatstatus | 0x100
		seatstatusntc.playercards =  seatobj.cards --玩家游戏数据
	end

	if seatobj.autocall ~= nil and  seatobj.autocall > 0 then
		seatstatusntc.seatstatus = seatstatusntc.seatstatus | 0x200
	end
	msghelper:sendmsg_to_tableplayer(seatobj, "SeatStatusNtc", seatstatusntc)
end

function RoomSeatLogic.srcTributeDes(srcseat,desseat)
	local srcCards = srcseat.cards;
	local desCards = desseat.cards;
	local maxCard = srcCards[#srcCards];
	for i=1,#srcCards do
		local srccard = srcCards[i];
		if (srccard.card_value ~= Joker.JokerC and maxCard.card_value < srccard.card_value) then
			maxCard = srccard
		elseif maxCard.card_value == Joker.JokerC and srccard.card_value ~= Joker.JokerC then
			maxCard = srccard
		end
	end
	cardtool.delCard(srcCards,maxCard)
	cardtool.insCard(desCards,maxCard)
	return maxCard;
end

function RoomSeatLogic.srcBackDesTimeout(srcseat,desseat)
	local srcCards = srcseat.cards;
	local desCards = desseat.cards;
	cardtool.sortByLaiziAsc(srcCards);
	local minCard = srcCards[1];
	cardtool.delCard(srcCards,minCard)
	cardtool.insCard(desCards,minCard)
	return minCard
end

function RoomSeatLogic.srcBackDes(srcseat,desseat,card)
	cardtool.delCard(srcseat.cards,card)
	cardtool.insCard(desseat.cards,card)
end

function RoomSeatLogic.delCards(seatobj,cards)
	cardtool.delCards(seatobj.cards,cards);
end

function RoomSeatLogic.insCards(seatobj,cards)
	cardtool.insCards(seatobj.cards,cards);
end

function RoomSeatLogic.findCards(seatobj,cards)
	return cardtool.findCards(seatobj.cards,cards);
end

function RoomSeatLogic.dealCards(seatobj,cards)
	RoomSeatLogic.delCards(seatobj,cards);
end

function RoomSeatLogic.setReady(seatobj,flag)
	seatobj.is_ready = flag;
end

function RoomSeatLogic.getMinDanCard(seatobj)
	cardtool.sortByLaiziAsc(seatobj.cards);
	return seatobj.cards[1]
end

return RoomSeatLogic