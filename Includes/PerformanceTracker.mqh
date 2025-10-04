//+------------------------------------------------------------------+
//| PerformanceTracker.mqh                                          |
//| Real-time performance monitoring                               |
//+------------------------------------------------------------------+

class CPerformanceTracker
{
private:
    double m_winRate;
    double m_profitFactor;
    double m_sharpeRatio;
    double m_maxDrawdown;
    
public:
    CPerformanceTracker();
    void UpdateMetrics();
    void LogPerformance();
    bool IsStrategyProfitable();
};

//+------------------------------------------------------------------+
//| Constructor                                                     |
//+------------------------------------------------------------------+
CPerformanceTracker::CPerformanceTracker()
{
    m_winRate = 0;
    m_profitFactor = 0;
    m_sharpeRatio = 0;
    m_maxDrawdown = 0;
}

//+------------------------------------------------------------------+
//| Update performance metrics                                      |
//+------------------------------------------------------------------+
void CPerformanceTracker::UpdateMetrics()
{
    int totalTrades = OrdersHistoryTotal();
    if(totalTrades == 0) return;
    
    int winningTrades = 0;
    double grossProfit = 0;
    double grossLoss = 0;
    double totalReturn = 0;
    double maxEquity = AccountInfoDouble(ACCOUNT_BALANCE);
    double minEquity = maxEquity;
    
    // Analyze trade history
    for(int i = 0; i < totalTrades; i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
        {
            double profit = OrderProfit() + OrderSwap() + OrderCommission();
            totalReturn += profit;
            
            if(profit > 0)
            {
                winningTrades++;
                grossProfit += profit;
            }
            else
            {
                grossLoss += MathAbs(profit);
            }
            
            // Update equity curve for drawdown calculation
            double currentEquity = AccountInfoDouble(ACCOUNT_BALANCE) + totalReturn;
            maxEquity = MathMax(maxEquity, currentEquity);
            minEquity = MathMin(minEquity, currentEquity);
        }
    }
    
    // Calculate metrics
    m_winRate = (double)winningTrades / totalTrades;
    m_profitFactor = grossLoss > 0 ? grossProfit / grossLoss : 0;
    m_maxDrawdown = maxEquity > 0 ? (maxEquity - minEquity) / maxEquity * 100.0 : 0;
    
    // Log performance periodically
    static datetime lastLog = 0;
    if(TimeCurrent() - lastLog >= 3600) // Log every hour
    {
        LogPerformance();
        lastLog = TimeCurrent();
    }
}

//+------------------------------------------------------------------+
//| Log performance to journal                                      |
//+------------------------------------------------------------------+
void CPerformanceTracker::LogPerformance()
{
    Print("=== PERFORMANCE METRICS ===");
    Print("Win Rate: ", DoubleToString(m_winRate * 100, 1), "%");
    Print("Profit Factor: ", DoubleToString(m_profitFactor, 2));
    Print("Max Drawdown: ", DoubleToString(m_maxDrawdown, 1), "%");
    Print("Total Trades: ", OrdersHistoryTotal());
    Print("===========================");
}

//+------------------------------------------------------------------+
//| Check if strategy is profitable                                |
//+------------------------------------------------------------------+
bool CPerformanceTracker::IsStrategyProfitable()
{
    return (m_winRate > 0.55 && m_profitFactor > 1.2 && m_maxDrawdown < 15.0);
}