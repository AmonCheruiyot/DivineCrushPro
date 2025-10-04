//+------------------------------------------------------------------+
//| AdvancedSignalGenerator.mqh                                     |
//| Institutional-grade signal generation                          |
//+------------------------------------------------------------------+

class CAdvancedSignalGenerator
{
private:
    // Market microstructure analysis
    double CalculateVolumeDelta(string symbol);
    double CalculateOrderFlowImbalance(string symbol);
    bool DetectInstitutionalAbsorption(string symbol);
    double CalculateMarketDepthPressure(string symbol);
    
    // Advanced pattern recognition
    bool DetectWyckoffAccumulation(string symbol);
    bool DetectMarketMakerTraps(string symbol);
    bool IdentifySmartMoneyLevels(string symbol);
    
    // Technical analysis components
    double CalculateRSIMomentum(string symbol);
    double CalculateMACDSignal(string symbol);
    double CalculateBollingerPosition(string symbol);
    double CalculateADXStrength(string symbol);
    
public:
    double GenerateEnhancedSignal(string symbol);
    double CalculateSignalConfidence(string symbol);
};

//+------------------------------------------------------------------+
//| Generate enhanced trading signal                               |
//+------------------------------------------------------------------+
double CAdvancedSignalGenerator::GenerateEnhancedSignal(string symbol)
{
    double signal = 0;
    int signalCount = 0;
    
    // 1. Volume Delta Analysis
    double volumeDelta = CalculateVolumeDelta(symbol);
    if(volumeDelta > 1000000) 
    {
        signal += 0.3;
        signalCount++;
    }
    else if(volumeDelta < -1000000)
    {
        signal -= 0.3;
        signalCount++;
    }
    
    // 2. RSI Momentum
    double rsiMomentum = CalculateRSIMomentum(symbol);
    signal += rsiMomentum;
    signalCount++;
    
    // 3. MACD Signal
    double macdSignal = CalculateMACDSignal(symbol);
    signal += macdSignal;
    signalCount++;
    
    // 4. Bollinger Bands Position
    double bollingerPos = CalculateBollingerPosition(symbol);
    signal += bollingerPos;
    signalCount++;
    
    // 5. Market Maker Trap Detection
    if(DetectMarketMakerTraps(symbol))
    {
        // If trap detected, reverse expected direction
        MqlRates rates[];
        ArraySetAsSeries(rates, true);
        CopyRates(symbol, PERIOD_M15, 0, 2, rates);
        
        if(rates[0].close > rates[0].open)
        {
            signal -= 0.4; // Bearish trap detected
        }
        else
        {
            signal += 0.4; // Bullish trap detected
        }
        signalCount++;
    }
    
    // 6. ADX Trend Strength
    double adxStrength = CalculateADXStrength(symbol);
    signal += (adxStrength * 0.2); // Weight ADX less
    signalCount++;
    
    // Normalize signal
    if(signalCount > 0)
        signal /= signalCount;
    
    return MathMin(MathMax(signal, -1.0), 1.0);
}

//+------------------------------------------------------------------+
//| Calculate signal confidence                                    |
//+------------------------------------------------------------------+
double CAdvancedSignalGenerator::CalculateSignalConfidence(string symbol)
{
    double confidence = 0.5; // Base confidence
    
    // 1. Volume confidence
    double volumeDelta = CalculateVolumeDelta(symbol);
    confidence += MathMin(MathAbs(volumeDelta) / 2000000.0, 0.2);
    
    // 2. ADX strength confidence
    double adxStrength = CalculateADXStrength(symbol);
    confidence += adxStrength * 0.15;
    
    // 3. RSI confidence (extremes are more reliable)
    double rsi = CalculateRSIMomentum(symbol);
    if(MathAbs(rsi) > 0.6)
        confidence += 0.15;
    
    return MathMin(MathMax(confidence, 0.0), 1.0);
}

//+------------------------------------------------------------------+
//| Calculate volume delta (buying vs selling pressure)            |
//+------------------------------------------------------------------+
double CAdvancedSignalGenerator::CalculateVolumeDelta(string symbol)
{
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    CopyRates(symbol, PERIOD_M5, 0, 20, rates);
    
    double volumeDelta = 0;
    for(int i = 0; i < 20; i++)
    {
        if(rates[i].close > rates[i].open)
            volumeDelta += rates[i].tick_volume;  // Buying pressure
        else if(rates[i].close < rates[i].open)
            volumeDelta -= rates[i].tick_volume;  // Selling pressure
    }
    
    return volumeDelta;
}

//+------------------------------------------------------------------+
//| Detect market maker traps (stop hunts, liquidity grabs)        |
//+------------------------------------------------------------------+
bool CAdvancedSignalGenerator::DetectMarketMakerTraps(string symbol)
{
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    CopyRates(symbol, PERIOD_M15, 0, 5, rates);
    
    // Look for long wicks with small bodies after a move
    for(int i = 0; i < 3; i++)
    {
        double upperWick = rates[i].high - MathMax(rates[i].open, rates[i].close);
        double lowerWick = MathMin(rates[i].open, rates[i].close) - rates[i].low;
        double body = MathAbs(rates[i].close - rates[i].open);
        
        // Market maker trap: Long wick with small body
        if((upperWick > body * 2 && rates[i].close < rates[i].open) || 
           (lowerWick > body * 2 && rates[i].close > rates[i].open))
        {
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Calculate RSI momentum                                         |
//+------------------------------------------------------------------+
double CAdvancedSignalGenerator::CalculateRSIMomentum(string symbol)
{
    double rsi = iRSI(symbol, PERIOD_H1, 14, PRICE_CLOSE, 0);
    
    if(rsi > 70) return -0.8;  // Overbought
    if(rsi > 60) return -0.4;  // Approaching overbought
    if(rsi < 30) return 0.8;   // Oversold
    if(rsi < 40) return 0.4;   // Approaching oversold
    
    return 0.0; // Neutral
}

//+------------------------------------------------------------------+
//| Calculate MACD signal                                          |
//+------------------------------------------------------------------+
double CAdvancedSignalGenerator::CalculateMACDSignal(string symbol)
{
    double macdMain = iMACD(symbol, PERIOD_H1, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0);
    double macdSignal = iMACD(symbol, PERIOD_H1, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 0);
    
    if(macdMain > macdSignal && macdMain > 0) return 0.6;
    if(macdMain < macdSignal && macdMain < 0) return -0.6;
    if(macdMain > macdSignal) return 0.3;
    if(macdMain < macdSignal) return -0.3;
    
    return 0.0;
}

//+------------------------------------------------------------------+
//| Calculate Bollinger Bands position                             |
//+------------------------------------------------------------------+
double CAdvancedSignalGenerator::CalculateBollingerPosition(string symbol)
{
    double upperBand = iBands(symbol, PERIOD_H1, 20, 2, 0, PRICE_CLOSE, MODE_UPPER, 0);
    double lowerBand = iBands(symbol, PERIOD_H1, 20, 2, 0, PRICE_CLOSE, MODE_LOWER, 0);
    double middleBand = iBands(symbol, PERIOD_H1, 20, 2, 0, PRICE_CLOSE, MODE_MAIN, 0);
    double currentPrice = SymbolInfoDouble(symbol, SYMBOL_BID);
    
    if(currentPrice <= lowerBand) return 0.8;   // Oversold
    if(currentPrice >= upperBand) return -0.8;  // Overbought
    if(currentPrice > middleBand) return 0.2;   // Upper half
    if(currentPrice < middleBand) return -0.2;  // Lower half
    
    return 0.0;
}

//+------------------------------------------------------------------+
//| Calculate ADX trend strength                                   |
//+------------------------------------------------------------------+
double CAdvancedSignalGenerator::CalculateADXStrength(string symbol)
{
    double adx = iADX(symbol, PERIOD_H1, 14, PRICE_CLOSE, MODE_MAIN, 0);
    
    if(adx > 25) return 1.0;  // Strong trend
    if(adx > 20) return 0.7;  // Moderate trend
    if(adx > 15) return 0.4;  // Weak trend
    
    return 0.0; // No trend
}