local tabletool = require "tabletool"
local base      = require "base"
--local timetool  = require "timetool"
require"cardvalue"
-- ColorType =
-- {
--     Spade = 1,         --黑桃
--     Heart = 2,         --红桃
--     Plum  = 3,         --樱花
--     Block = 4,         --方块
-- }

-- CardType =
-- {
--     UNDEFINE=0,        --高牌
--     DUI_ZI  =1,          --对子
--     SHUN_ZI =2,         --顺子
--     TONG_HUA=3,   --同花
--     TONG_HUA_SHUN = 4, --同花顺
--     BAO_ZI = 5,        --豹子


-- }

local cardTool = {

}

----------------------------------------------------《牌型控制工具函数》----------------------------
function cardTool.RandCardList()
    --混乱准备
    local bufferCount = #CardData;

    --混乱扑克
    local randCount = 1;
    local position = 1;

    local tmp_seed = base.RNG()
    if tmp_seed == nil then
        tmp_seed = timetool.get_10ms_time() --  + (seed or 0)
    end
    math.randomseed(tmp_seed) 

    -- repeat
    --     position = math.random(bufferCount - randCount + 1);
    --     cardBuffer[randCount] = tmpCardData[position];
    --     tmpCardData[position] = tmpCardData[bufferCount - randCount + 1];
    --     randCount = randCount + 1;
    -- until (randCount > bufferCount)
        
    for i = 1,#CardData do
        local ranOne = base.get_random(1,#CardData+1-i)
        CardData[ranOne], CardData[#CardData+1-i] = CardData[#CardData+1-i],CardData[ranOne]
    end

    local cardBuffer = tabletool.deepcopy(CardData);
    return cardBuffer;
end

-------------------------------------------------------1.1常用table操作方法-------------------------
function compByPaiziAscending(a, b)

    return a.card_value < b.card_value
   
end


--------------------------------------------------------2.1按花色排序--------------------------------
-- function compByCardsTypeDescending(a,b)

--     if(a.card_laizireplacevalue >= Joker.JokerA or  b.card_laizireplacevalue >= Joker.JokerB) then
--         return (a.card_laizireplacevalue> b.card_laizireplacevalue and true or false)
--     else
--         local a_point = a.card_value 
--         local a_suit = a.card_type 
--         local b_point = b.card_value; 
--         local b_suit = b.card_type;
--         if (a_suit == a_suit) then
--             return (a_point > b_point and true or false) 
--         end

--         if (a_suit > a_suit) then
--             return (a_suit > b_suit and true or false) 
            
--         end
--         --  黑桃, 红桃, 梅花,方片
--     end
-- end

--------------------------------------------------------2.2按牌值排序-------------------------------------
function cardTool.sortByLaiziAsc(cards)
    table.sort(cards, compByPaiziAscending);
end

--------------------------------------------------------3.1查找牌型----------------------------------------
function cardTool.findCards(srccards,cards)
    local b = false;
    if (not srccards or not cards) then
        return b
    end
    
    for i=1,#cards do
        if (cardTool.findCard(srccards,cards[i])) then
            b = true;
            break;
        end
    end

    return b;
end

function cardTool.findCard(srccards,card)
    for i=1,#srccards do
        local src = srccards[i]
        if (src.card_type == card.card_type and
             src.card_value == card.card_value) then
            return true
        end
    end

    return false;
end


---------------------------------------------------------4.1牌型判断---------------------------------------
--》豹子
function cardTool.isBaozi( cards)
  
    -- if cards == nil
    
    -- else
    --     if #cards > 3 or #cards < 0

    --     end 
    -- end 

    local FristCardValue = cards[1].card_value
    local SameCardValueNumbers = 0

    for i, v in pairs(cards) do
        if v.card_value == FristCardValue then
            SameCardValueNumbers = SameCardValueNumbers + 1;
        end
    end

    if SameCardValueNumbers == 3 then
        return true
    else
        return false
    end

end


--》同花顺 
function cardTool.isTongHuaShun(cards)
 
    -- if cards == nil
    
    -- else
    --     if #cards > 3 or #cards < 0

    --     end 
    -- end

    local TagTongHua
    local TagShunZi

    TagTongHua = cardTool.isTongHua(cards)
    TagShunZi  = cardTool.isShunZi(cards)

    if TagTongHua and TagShunZi then --既满足同花也满足顺子的时候，就是同花顺，包含23A
        return true
    else
        return false
    end

end

--》同花
function cardTool.isTongHua (cards)
 
    -- if cards == nil
    
    -- else
    --     if #cards > 3 or #cards < 0

    --     end 
    -- end

    local FristCardColor = cards[1].card_type
    local SameCardColorNumbers = 0
    for i, v in pairs(cards) do
        if v.card_type == FristCardColor then
            SameCardColorNumbers = SameCardColorNumbers + 1
        end
    end

    if SameCardColorNumbers == 3 then
        return true
    else
        return false
    end

end


--》顺子
function cardTool.isShunZi(cards)
    -- if cards == nil
    
    -- else
    --     if #cards > 3 or #cards < 0

    --     end 
    -- end

    local  NextSubLastToOne = 0 --牌值差为1的次数
    local  NextSubLast          --升序排列的牌形，相邻之间的差值
    local cardsvalue = {}

    for i=1, 3, 1 do
    table.insert(cardsvalue, cards[i].card_value)
    end

    for i=2, 3, 1 do
        NextSubLast = cardsvalue[i] - cardsvalue[i-1]
        if NextSubLast ~= 1 then
            if (cardsvalue[i] - cardsvalue[2]) == 11 then --判断23A这种情况
                --print("my card is A23")
                return true
            else
                return false
            end
        end

        if NextSubLast == 1 then
            NextSubLastToOne = NextSubLastToOne + 1
        end
    end

    if NextSubLastToOne == 2 then   
        return true
    end

end


--》对子，不会将三张相同的牌（豹子）也判断为对子
function cardTool.isDuiZi(cards)
   
    -- if cards == nil
    
    -- else
    --     if #cards > 3 or #cards < 0

    --     end 
    -- end

    local cardsvalue = {}
    local SamCardNumbers = 0

    for i=1, 3, 1 do
        table.insert(cardsvalue, cards[i].card_value)
    end

    if cardsvalue[1] ~= cardsvalue[3] then
        if cardsvalue[1] == cardsvalue[2] then
            return true
        end

        if cardsvalue[2] == cardsvalue[3] then
            return true
        end
    else
        return false
    end

end

---------------------------------------------------------5.1牌型确认--------------------------------------
--cardType:牌型
function cardTool.getCardType(cards)
    cardTool.sortByLaiziAsc(cards)
    -- if cards == nil
    
    -- else
    --     if #cards > 3 or #cards < 0

    --     end 
    -- end

    local card_type = CardType.UNDEFINE
    local ret

    if (cards) then
        --《豹子
        ret = cardTool.isBaozi(cards)
        if ret == true then
            card_type = CardType.BAO_ZI
            return card_type 
        end

        --《同花顺
        ret = cardTool.isTongHuaShun(cards)
        if (ret == true) then
            card_type = CardType.TONG_HUA_SHUN;
            return card_type

        end

        --《同花
        ret = cardTool.isTongHua(cards)
        if (ret == true) then
            card_type = CardType.TONG_HUA;
            return card_type
        end

        --《顺子
        ret = cardTool.isShunZi(cards)
        if (ret == true) then
            card_type = CardType.SHUN_ZI;
            return card_type
        end
        
        -- 《对子
        ret = cardTool.isDuiZi(cards)
        if (ret == true) then
            card_type = CardType.DUI_ZI;
            return card_type
        end
    end

    return card_type  --UNDEFINE=0,--高牌，参见cardvalue.lua

end

---------------------------------------------------------6.1牌型比较---------------------------------------------------------
--@ my_Cards, 本家出牌,
--@ pre_Cards,下家出牌,
--@ ret true/false
function cardTool.isOvercomePrev(my_Cards, next_Cards)
    -- if my_Cards == nil
    
    -- else
    --     if #my_Cards > 3 or #my_Cards < 0

    --     end 
    -- end

    -- if next_Cards == nil
    
    -- else
    --     if #next_Cards > 3 or #next_Cards < 0

    --     end 
    -- end

    --获取各自牌形
    local my_Cards_Type = cardTool.getCardType(my_Cards)
    local next_Cards_Type = cardTool.getCardType(next_Cards)
    local winorlose
    if  my_Cards_Type == next_Cards_Type then --牌形相同的情况下
        --print("pai  is  Same ")
        winorlose =  CardTypeSame(my_Cards, next_Cards, my_Cards_Type)
    end

    if my_Cards_Type ~= next_Cards_Type  then --牌形不同的情况下
        --print("pai is butong ")
        winorlose =  CardTypeDifferent(my_Cards, next_Cards,my_Cards_Type,next_Cards_Type)
    end
	
	return winorlose
end

function  CardTypeDifferent( my_Cards, next_Cards, my_Cards_Type, next_Cards_Type )
    --print("mycards type",my_Cards_Type)
	--print("nextcards type",next_Cards_Type)
	local  win  = true
    local  lose = false

    local isWinOrlose
    local HaveBaoZiOrNot

    local my_Cards_Bao_Zi = false
    local next_Cards_Bao_Zi = false

    local my_Cards_A32 
    local next_Cards_A32 

    if my_Cards_Type == CardType.BAO_ZI then
        my_Cards_Bao_Zi = true
    end

    if next_Cards_Type == CardType.BAO_ZI then
        next_Cards_Bao_Zi = true
    end

    --如果没有豹子
    if (my_Cards_Bao_Zi == false) and (next_Cards_Bao_Zi == false) then
        --print("no baozi")
        isWinOrlose = my_Cards_Type - next_Cards_Type
        if isWinOrlose > 0 then
            --print("my cards > nextcards card_value")
            return win
        end

        if isWinOrlose < 0 then
            --print(" my cards < nextcards card_value")
            return lose
        end
    end
    --print("++++++++++")
    --如果有豹子
    if my_Cards_Bao_Zi or next_Cards_Bao_Zi then
	    --print("have baozi ")    
		my_Cards_235 = is235(my_Cards)
        next_Cards_235 = is235(next_Cards)
        if my_Cards_235  then
			--print("my car is 235")
            if cardTool.isTongHua(my_Cards) then
                return lose
            else
                return win
            end
		end

        if next_Cards_235 then
			--print("next card is 235")
            if cardTool.isTongHua(next_Cards) then
                return win
            else
                return lose
			end
        end
		
		if (my_Cards_235 == false) and (next_Cards_235 == false) then
			--print("dou bushi 235")
			if 	my_Cards_Type == CardType.BAO_ZI then
				--print("my card is baozi")
				return win
			end

			if next_Cards_Type == CardType.BAO_ZI then
				--print("next card is baozi")
				return lose
			end
    	end
	end
end

function CardTypeSame( my_Cards, next_Cards, my_Cards_Type )
   --print("pai xing is ", my_Cards_Type)
    --------------------------------------豹子-----------------------------
	local  win  = true
    local  lose = false
    local  SubValueBaoZi
    if  my_Cards_Type == CardType.Bao_ZI then
		--print("____________________")
        SubValueBaoZi = my_Cards[1].card_value - next_Cards[1].card_value
        if  SubValueBaoZi == 0 then
            return lose
        end
        if SubValueBaoZi > 0 then
			--print("this is win")
            return win
        end
        if SubValueBaoZi < 0 then
			--print("this is lose")
            return lose
        end
    end
    --print("+++++++++++++++++",type(SubValueBaoZi))
    -------------------------------------同花顺-----------------------------
    local TagA_mycards
    local TagA_nextcards
    local SubValueTonHaSu 
    if  my_Cards_Type == CardType.TONG_HUA_SHUN then
        if my_Cards[3].card_value == 14 then
            TagA_mycards = true
        end

        if next_Cards[3].card_value == 14 then
            TagA_nextcards = true
        end

        --都拿到A 
        if TagA_mycards and TagA_nextcards then
            SubValueTonHaSu = my_Cards[2].card_value - next_Cards[2].card_value
            if SubValueTonHaSu == 0 then
                return lose
            end
            if SubValueTonHaSu > 0 then
                return win
            end
            if SubValueTonHaSu < 0 then
                return lose
            end
        end

        --有一家拿到A
        if TagA_mycards or TagA_nextcards then
            if TagA_mycards == true then
                --print("my cards is A")
                return win
            end

            if TagA_nextcards == true then
                --print("nextcards is A23")
                return lose
            end
        end

        --都没拿到A
        if TagA_mycards == false and TagA_nextcards == false then
            SubValueTonHaSu = my_Cards[3].card_value - next_Cards[3].card_value
            if SubValueTonHaSu == 0 then
                return lose
            end
            if SubValueTonHaSu > 0 then
                return win
            end
            if SubValueTonHaSu < 0 then
                return lose
            end
        end
    end

    --------------------------------------------同花----------------------------------
    local AddValue_my_cards = 0
    local AddValue_next_cards = 0
    if  my_Cards_Type == CardType.TONG_HUA then
        -- for i, v in pairs(my_Cards) do
        --     AddValue_my_cards = AddValue_my_cards + v.card_value
        -- end
        -- for i, v in pairs(next_Cards) do
        --     AddValue_next_cards = AddValue_next_cards + v.card_value
        -- end

        -- if AddValue_my_cards > AddValue_next_cards then
        --     return win
        -- end

        -- if AddValue_my_cards < AddValue_next_cards then
        --     return lose
        -- end

        -- if AddValue_my_cards == AddValue_next_cards then
        --     return lose
        -- end
        if my_Cards[3].card_value - next_Cards[3].card_value > 0 then
            return true
        end

        if my_Cards[3].card_value - next_Cards[3].card_value < 0 then
            return false
        end

        if my_Cards[3].card_value - next_Cards[3].card_value == 0 then
            if my_Cards[2].card_value - next_Cards[2].card_value > 0 then
                return true
            end

            if my_Cards[2].card_value - next_Cards[2].card_value < 0 then
                return false
            end

            if my_Cards[2].card_value - next_Cards[2].card_value == 0 then
                if my_Cards[1].card_value - next_Cards[1].card_value > 0 then
                    return true
                end

                if my_Cards[1].card_value - next_Cards[1].card_value < 0 then
                    return false
                end

                if my_Cards[1].card_value - next_Cards[1].card_value == 0 then
                    return false
                end
            end
        end
    end
    
    --------------------------------------------顺子----------------------------------
    local  IsOrNotA32_mycards
    local  IsOrNotA32_nextcards
    local  SubValueSunZi
    if  my_Cards_Type == CardType.SHUN_ZI then

        IsOrNotA32_mycards = isA32(my_Cards)
        IsOrNotA32_nextcards = isA32(next_Cards)

        --两个都是A32
        if IsOrNotA32 and IsOrNotA32_nextcards then
            return lose
        end

        --有一个有A32
        if IsOrNotA32 or IsOrNotA32_nextcards then
            if IsOrNotA32_mycards then
                return win
            else
                return lose
            end
        end

        --都没有A32
        if IsOrNotA32 == false and IsOrNotA32_nextcards == false then
            SubValueSunZi = my_Cards[3].card_value - next_Cards[3].card_value
            if SubValueSunZi == 0 then
                return lose
            end
            if SubValueSunZi > 0 then
                return win
            end
            if SubValueSunZi < 0 then
                return lose
            end
        end
    end

    --------------------------------------------对子----------------------------------
    local SubValueDuiZi
    local AddValue_my_cards_Dui --所有牌值求和
    local AddValue_next_cards_next
    if  my_Cards_Type == CardType.DUI_ZI then

        SubValueDuiZi = my_Cards[2].card_value - next_Cards[2].card_value
        AddValue_my_cards_Dui = AddValu_cards(my_Cards)
        AddValue_next_cards_next = AddValu_cards(next_Cards)
    
        --第二张相等
        if SubValueDuiZi == 0 then
            if AddValue_my_cards_Dui > AddValue_next_cards_next then
                return win
            end
            if AddValue_my_cards_Dui < AddValue_next_cards_next then
                return lose
            end
            if AddValue_my_cards_Dui == AddValue_next_cards_next then
                return lose
            end
        end

        --第二张不等
        if SubValueDuiZi > 0 then
            return win 
        end
        if SubValueDuiZi < 0 then
            return lose
        end
    end

    --------------------------------------------高牌----------------------------------
    if  my_Cards_Type == CardType.UNDEFINE then
        return GaoPaiPcall(my_Cards, next_Cards) --回调函数判断每一张牌
	end
end

--》便于高牌比较输赢的回调函数
function GaoPaiPcall(my_Cards, next_Cards)
    if my_Cards[3].card_value - next_Cards[3].card_value > 0 then
        return true
    end

    if my_Cards[3].card_value - next_Cards[3].card_value < 0 then
        return false
    end

    if my_Cards[3].card_value - next_Cards[3].card_value == 0 then
        if my_Cards[2].card_value - next_Cards[2].card_value > 0 then
            return true
        end

        if my_Cards[2].card_value - next_Cards[2].card_value < 0 then
            return false
        end

        if my_Cards[2].card_value - next_Cards[2].card_value == 0 then
            if my_Cards[1].card_value - next_Cards[1].card_value > 0 then
                return true
            end

            if my_Cards[1].card_value - next_Cards[1].card_value < 0 then
                return false
            end

            if my_Cards[1].card_value - next_Cards[1].card_value == 0 then
                return false
            end
        end
    end
end

function AddValu_cards( cards )
    local value = 0
    for i, v in pairs(cards) do
        value = value  + v.card_value
    end
    return value
end

--》便于确定是否含23A的方法
function isA32(cards)
    local num = 0
    for i = 1, 3, 1 do
        if i == 1 then
            if cards[i].card_value == 2 then
                num = num + 1
            end
        end

        if i == 2 then
            if cards[i].card_value == 3 then
                num = num + 1
            end
        end

        if i == 3 then
           if  cards[i].card_value == 14 then
                 num = num + 1
           end
        end
    end

    if num == 3 then
        return true
    else
        return false
    end
end

--》235
function is235(cards)
    local num = 0
    for i = 1, 3, 1 do
        if i == 1 then
            if cards[i].card_value == 2 then
                num = num + 1
            end
        end

        if i == 2 then
            if cards[i].card_value == 3 then
                num = num + 1
            end
        end

        if i == 3 then
            if  cards[i].card_value == 5 then
                num = num + 1
            end
        end
    end

    if num == 3 then
        return true
    else
        return false
    end
end

return cardTool

-- table1 = {
-- 			{card_value = 3,card_type = 3},
-- 			{card_value = 2,card_type = 2},
-- 			{card_value = 7,card_type = 2},
-- 		}


-- table2 = {
-- 			{card_value = 4,card_type = 2},
-- 			{card_value = 2,card_type = 3},
-- 			{card_value = 7,card_type = 3},
-- 		}




-- if cardTool.isOvercomePrev(table1, table2)  then
--     print("table1")
-- else
--     print("table2")
-- end


