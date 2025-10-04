//+------------------------------------------------------------------+
//| TradeExecutor.mqh                                               |
//| Professional trade execution                                   |
//+------------------------------------------------------------------+

class CTradeExecutor
{
private:
    long m_magicNumber;
    int m_slippage;
    bool m_useImprovedExecution;
    
    double CalculateOptimalEntry(string symbol, ENUM_ORDER_TYPE orderType);
    double CalculateDynamicStopLoss(string symbol, ENUM_ORDER_TYPE orderType, double entryPrice, double confidence);
    double CalculateDynamicTakeProfit(string symbol, ENUM_ORDER_TYPE orderType, double entryPrice, double stopLoss, double confidence);
    bool ModifyToBreakeven(string symbol);
    bool TrailStopLoss(string symbol);
    
public:
    CTradeExecutor(long magic, int slippage, bool improvedExecution);
    
    bool ExecuteTrade(string symbol, ENUM_ORDER_TYPE orderType, double volume, double confidence, bool useDynamicStops);
    bool HasOpenPosition(string symbol);
    void ManagePosition(string symbol);
};

//+------------------------------------------------------------------+
//| Constructor                                                     |
//+------------------------------------------------------------------+
CTradeExecutor::CTradeExecutor(long magic, int slippage, bool improvedExecution)
{
    m_magicNumber = magic;
    m_slippage = slippage;
    m_useImprovedExecution = improvedExecution;
}

//+------------------------------------------------------------------+
//| Execute trade with professional risk management                |
//+------------------------------------------------------------------+
bool CTradeExecutor::ExecuteTrade(string symbol, ENUM_ORDER_TYPE orderType, double volume, double confidence, bool useDynamicStops)
{
    // Calculate optimal entry price
    double entryPrice = CalculateOptimalEntry(symbol, orderType);
    
    // Calculate stops
    double stopLoss = 0;
    double takeProfit = 0;
    
    if(useDynamicStops)
    {
        stopLoss = CalculateDynamicStopLoss(symbol, orderType, entryPrice, confidence);
        takeProfit = CalculateDynamicTakeProfit(symbol, orderType, entryPrice, stopLoss, confidence);
    }
    
    // Prepare trade request
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = symbol;
    request.volume = volume;
    request.type = orderType;
    request.price = entryPrice;
    request.sl = stopLoss;
    request.tp = takeProfit;
    request.deviation = m_slippage;
    request.magic = m_magicNumber;
    request.comment = "DivineCrush: " + DoubleToString(confidence, 2);
    
    // Execute trade
    bool success = OrderSend(request, result);
    
    if(success && result.retcode == TRADE_RETCODE_DONE)
    {
        Print("Trade executed: ", symbol, " ", EnumToString(orderType), 
              " at ", DoubleToString(result.price, 5),
              " SL: ", DoubleToString(stopLoss, 5),
              " TP: ", DoubleToString(takeProfit, 5));
        return true;
    }
    else
    {
        Print("Trade execution failed: ", symbol, " Error: ", result.retcode);
        return false;
    }
}

//+------------------------------------------------------------------+
//| Calculate optimal entry price with improved execution          |
//+------------------------------------------------------------------+
double CTradeExecutor::CalculateOptimalEntry(string symbol, ENUM_ORDER_TYPE orderType)
{
    double currentBid = SymbolInfoDouble(symbol, SYMBOL_BID);
    double currentAsk = SymbolInfoDouble(symbol, SYMBOL_ASK);
    
    if(!m_useImprovedExecution)
    {
        // Basic execution - use current price
        return (orderType == ORDER_TYPE_BUY) ? currentAsk : currentBid;
    }
    
    // Improved execution - try to get better price
    if(orderType == ORDER_TYPE_BUY)
    {
        // For buys, try to get slightly below ask
        return currentAsk - (SymbolInfoDouble(symbol, SYMBOL_POINT) * 2);
    }
    else
    {
        // For sells, try to get slightly above bid
        return currentBid + (SymbolInfoDouble(symbol, SYMBOL_POINT) * 2);
    }
}

//+------------------------------------------------------------------+
//| Calculate dynamic stop loss based on ATR and confidence        |
//+------------------------------------------------------------------+
double CTradeExecutor::CalculateDynamicStopLoss(string symbol, ENUM_ORDER_TYPE orderType, double entryPrice, double confidence)
{
    double atr = iATR(symbol, PERIOD_H1, 14, 0);
    
    // Confidence-based stop adjustment
    // Higher confidence = tighter stop (more conviction)
    double stopMultiplier = 2.0 - (confidence * 1.5);
    stopMultiplier = MathMax(stopMultiplier, 0.5); // Minimum 0.5 ATR
    
    if(orderType == ORDER_TYPE_BUY)
    {
        return entryPrice - (atr * stopMultiplier);
    }
    else
    {
        return entryPrice + (atr * stopMultiplier);
    }
}

//+------------------------------------------------------------------+
//| Calculate dynamic take profit based on risk-reward ratio       |
//+------------------------------------------------------------------+
double CTradeExecutor::CalculateDynamicTakeProfit(string symbol, ENUM_ORDER_TYPE orderType, double entryPrice, double stopLoss, double confidence)
{
    double risk = MathAbs(entryPrice - stopLoss);
    
    // Confidence-based reward ratio
    // Higher confidence = higher reward target
    double rewardRatio = 1.5 + (confidence * 0.5); // 1.5:1 to 2.0:1
    
    if(orderType == ORDER_TYPE_BUY)
    {
        return entryPrice + (risk * rewardRatio);
    }
    else
    {
        return entryPrice - (risk * rewardRatio);
    }
}

//+------------------------------------------------------------------+
//| Check if there's an open position for symbol                   |
//+------------------------------------------------------------------+
bool CTradeExecutor::HasOpenPosition(string symbol)
{
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(PositionGetSymbol(i) == symbol && PositionGetInteger(POSITION_MAGIC) == m_magicNumber)
            return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Manage open position (trailing stops, breakeven)               |
//+------------------------------------------------------------------+
void CTradeExecutor::ManagePosition(string symbol)
{
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(PositionGetSymbol(i) == symbol && PositionGetInteger(POSITION_MAGIC) == m_magicNumber)
        {
            // Apply trailing stop logic
            TrailStopLoss(symbol);
            
            // Apply breakeven logic
            ModifyToBreakeven(symbol);
        }
    }
}

//+------------------------------------------------------------------+
//| Trail stop loss as price moves in our favor                   |
//+------------------------------------------------------------------+
bool CTradeExecutor::TrailStopLoss(string symbol)
{
    // Implementation for trailing stops
    // This would track price movement and adjust stops accordingly
    return true;
}

//+------------------------------------------------------------------+
//| Move stop loss to breakeven when trade is profitable          |
//+------------------------------------------------------------------+
bool CTradeExecutor::ModifyToBreakeven(string symbol)
{
    // Implementation for breakeven stops
    // This would move SL to entry price when trade reaches certain profit
    return true;
}