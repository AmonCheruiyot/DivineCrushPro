//+------------------------------------------------------------------+
//| AdvancedRiskManager.mqh                                         |
//| Institutional-grade risk management                            |
//+------------------------------------------------------------------+

class CAdvancedRiskManager
{
private:
    double m_riskPercent;
    double m_maxDailyLossPercent;
    double m_maxDrawdownPercent;
    
    // Performance tracking
    double GetHistoricalWinRate(string symbol);
    double GetAverageWin(string symbol);
    double GetAverageLoss(string symbol);
    
public:
    CAdvancedRiskManager(double riskPercent, double maxDailyLoss, double maxDrawdown);
    
    double CalculateOptimalPositionSize(string symbol, double signalStrength, double confidence);
    bool ShouldTakeTrade(string symbol, double proposedSize);
    double CalculateKellyFraction(string symbol);
};

//+------------------------------------------------------------------+
//| Constructor                                                     |
//+------------------------------------------------------------------+
CAdvancedRiskManager::CAdvancedRiskManager(double riskPercent, double maxDailyLoss, double maxDrawdown)
{
    m_riskPercent = riskPercent;
    m_maxDailyLossPercent = maxDailyLoss;
    m_maxDrawdownPercent = maxDrawdown;
}

//+------------------------------------------------------------------+
//| Calculate optimal position size using Kelly + volatility        |
//+------------------------------------------------------------------+
double CAdvancedRiskManager::CalculateOptimalPositionSize(string symbol, double signalStrength, double confidence)
{
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    // Base risk amount
    double baseRiskAmount = balance * (m_riskPercent / 100.0);
    
    // Kelly criterion position sizing
    double kellyFraction = CalculateKellyFraction(symbol);
    
    // Volatility adjustment
    double atr = iATR(symbol, PERIOD_H1, 14, 0);
    double pointValue = SymbolInfoDouble(symbol, SYMBOL_POINT);
    double volatilityAdjustment = 1.0 / MathMax(atr / pointValue * 0.0001, 0.1);
    
    // Signal strength multiplier
    double signalMultiplier = 0.5 + (signalStrength * 0.5);
    
    // Confidence multiplier
    double confidenceMultiplier = 0.5 + (confidence * 0.5);
    
    // Calculate raw position size
    double rawSize = baseRiskAmount * kellyFraction * volatilityAdjustment * signalMultiplier * confidenceMultiplier;
    
    // Convert to lots based on symbol specifications
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double lotSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
    
    double positionSize = rawSize / (tickSize * tickValue * lotSize);
    
    // Apply limits
    double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    double stepLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    
    positionSize = MathMax(positionSize, minLot);
    positionSize = MathMin(positionSize, maxLot);
    
    // Normalize to step size
    if(stepLot > 0)
        positionSize = MathRound(positionSize / stepLot) * stepLot;
    
    // Final risk check - don't risk more than 5% per trade
    double maxRiskSize = balance * 0.05 / (tickSize * tickValue * lotSize);
    positionSize = MathMin(positionSize, maxRiskSize);
    
    return NormalizeDouble(positionSize, 2);
}

//+------------------------------------------------------------------+
//| Calculate Kelly fraction for position sizing                   |
//+------------------------------------------------------------------+
double CAdvancedRiskManager::CalculateKellyFraction(string symbol)
{
    double winRate = GetHistoricalWinRate(symbol);
    double avgWin = GetAverageWin(symbol);
    double avgLoss = GetAverageLoss(symbol);
    
    // Avoid division by zero
    if(avgLoss == 0 || winRate <= 0)
        return 0.01; // Conservative default
    
    double winLossRatio = avgWin / MathAbs(avgLoss);
    
    // Kelly formula: f = (p * b - q) / b
    double kellyFraction = (winRate * winLossRatio - (1 - winRate)) / winLossRatio;
    
    // Use fractional Kelly (25%) for safety
    double fractionalKelly = MathMax(kellyFraction * 0.25, 0.01);
    
    return MathMin(fractionalKelly, 0.05); // Cap at 5%
}

//+------------------------------------------------------------------+
//| Get historical win rate for symbol                             |
//+------------------------------------------------------------------+
double CAdvancedRiskManager::GetHistoricalWinRate(string symbol)
{
    // In a real implementation, you would query your trade history
    // For now, return a reasonable default
    return 0.65; // 65% win rate assumption
}

//+------------------------------------------------------------------+
//| Get average win amount                                         |
//+------------------------------------------------------------------+
double CAdvancedRiskManager::GetAverageWin(string symbol)
{
    // In real implementation, calculate from trade history
    return 85.0; // $85 average win
}

//+------------------------------------------------------------------+
//| Get average loss amount                                        |
//+------------------------------------------------------------------+
double CAdvancedRiskManager::GetAverageLoss(string symbol)
{
    // In real implementation, calculate from trade history
    return 50.0; // $50 average loss
}

//+------------------------------------------------------------------+
//| Check if trade should be taken                                 |
//+------------------------------------------------------------------+
bool CAdvancedRiskManager::ShouldTakeTrade(string symbol, double proposedSize)
{
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    // Check daily loss limit
    if(equity < balance * (1 - m_maxDailyLossPercent / 100.0))
        return false;
    
    // Check maximum drawdown
    double drawdown = (balance - equity) / balance * 100.0;
    if(drawdown >= m_maxDrawdownPercent)
        return false;
    
    // Check margin requirements
    double marginRequired = proposedSize * SymbolInfoDouble(symbol, SYMBOL_MARGIN_INITIAL);
    double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    
    if(marginRequired > freeMargin * 0.5) // Don't use more than 50% of free margin
        return false;
    
    return true;
}