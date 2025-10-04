//+------------------------------------------------------------------+
//| SignalFilter.mqh                                                |
//| Professional signal filtering                                  |
//+------------------------------------------------------------------+

class CSignalFilter
{
private:
    bool m_enableMarketRegime;
    bool m_enableVolatility;
    bool m_enableTimeFilter;
    
    double CalculateMarketRegime(string symbol);
    double CalculateVolatilityRatio(string symbol);
    bool IsHighImpactNewsTime();
    
public:
    CSignalFilter(bool enableRegime, bool enableVolatility, bool enableTime);
    bool PassesAllFilters(string symbol, double signalStrength, string direction);
};

//+------------------------------------------------------------------+
//| Constructor                                                     |
//+------------------------------------------------------------------+
CSignalFilter::CSignalFilter(bool enableRegime, bool enableVolatility, bool enableTime)
{
    m_enableMarketRegime = enableRegime;
    m_enableVolatility = enableVolatility;
    m_enableTimeFilter = enableTime;
}

//+------------------------------------------------------------------+
//| Check if signal passes all filters                             |
//+------------------------------------------------------------------+
bool CSignalFilter::PassesAllFilters(string symbol, double signalStrength, string direction)
{
    // 1. Market Regime Filter
    if(m_enableMarketRegime)
    {
        double regime = CalculateMarketRegime(symbol);
        if(regime < 0.3) // Choppy market
        {
            // Only take high-confidence signals in choppy markets
            if(signalStrength < 0.7)
                return false;
        }
    }
    
    // 2. Volatility Filter
    if(m_enableVolatility)
    {
        double volatilityRatio = CalculateVolatilityRatio(symbol);
        if(volatilityRatio > 2.0) // Too volatile
            return false;
    }
    
    // 3. Time Filter
    if(m_enableTimeFilter)
    {
        if(IsHighImpactNewsTime())
            return false;
            
        MqlDateTime timeNow;
        TimeCurrent(timeNow);
        
        // Avoid trading during low liquidity periods
        if(timeNow.hour >= 21 || timeNow.hour <= 2) // Late NY to early Asia
            return false;
    }
    
    // 4. Spread Filter
    long spread = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
    if(spread > 20) // 2 pips max
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate market regime (trending vs choppy)                   |
//+------------------------------------------------------------------+
double CSignalFilter::CalculateMarketRegime(string symbol)
{
    double adx = iADX(symbol, PERIOD_H1, 14, PRICE_CLOSE, MODE_MAIN, 0);
    
    if(adx > 25) return 1.0;      // Strong trend
    if(adx > 20) return 0.7;      // Moderate trend
    if(adx > 15) return 0.4;      // Weak trend
    if(adx > 10) return 0.2;      // Very weak trend
    
    return 0.1;                   // Choppy/Ranging
}

//+------------------------------------------------------------------+
//| Calculate volatility ratio (current vs average)                |
//+------------------------------------------------------------------+
double CSignalFilter::CalculateVolatilityRatio(string symbol)
{
    double currentAtr = iATR(symbol, PERIOD_H1, 14, 0);
    double averageAtr = iMA(symbol, PERIOD_H1, 50, 0, MODE_SMA, PRICE_TYPICAL, 1);
    
    if(averageAtr == 0) return 1.0;
    
    return currentAtr / averageAtr;
}

//+------------------------------------------------------------------+
//| Check if current time is high-impact news period               |
//+------------------------------------------------------------------+
bool CSignalFilter::IsHighImpactNewsTime()
{
    MqlDateTime timeNow;
    TimeCurrent(timeNow);
    
    // NFP (first Friday of month, 8:30 AM EST)
    if(timeNow.day_of_week == 5 && timeNow.hour == 13 && timeNow.min >= 25 && timeNow.min <= 35)
        return true;
    
    // FOMC meetings (approximate times)
    if(timeNow.hour == 19 && timeNow.min >= 0 && timeNow.min <= 30)
        return true;
    
    // CPI releases (typically 8:30 AM EST)
    if(timeNow.hour == 13 && timeNow.min >= 25 && timeNow.min <= 35)
        return true;
    
    return false;
}