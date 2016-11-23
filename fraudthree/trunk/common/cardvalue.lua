
ColorType =
{
    Spade = 1,         --黑桃
    Heart = 2,         --红桃
    Plum  = 3,         --樱花
    Block = 4,         --方块
}

CardType =
{
    UNDEFINE=0,        --高牌
    DUI_ZI  =1,          --对子
    SHUN_ZI =2,         --顺子
    TONG_HUA=3,   --同花
    TONG_HUA_SHUN = 4, --同花顺
    BAO_ZI = 5,        --豹子


}

--扑克数据
CardData=
{
    0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,0x0E,   --黑桃 2 - A(14)
    0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1A,0x1B,0x1C,0x1D,0x1E,   --红桃 2 - A
    0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x29,0x2A,0x2B,0x2C,0x2D,0x2E,   --樱花 2 - A
    0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x3A,0x3B,0x3C,0x3D,0x3E,   --方块 2 - A
}

g_CardsCount            = 52     --扑克数目
g_PerPlaCardCount       = 3      --每个玩家牌数
g_CardDivisor           = 0x10    --用来配合CardData计算花色
g_HeartDivisor          = 0x10    --用来配合红桃
g_PlumDivisor           = 0x20    --用来配合樱花
g_BlockDivisor          = 0x30    --用来配合方块