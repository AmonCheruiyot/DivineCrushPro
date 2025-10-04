//+------------------------------------------------------------------+
//| DivineCrushPro.mq5                                              |
//| Professional EA to outperform Pine Script strategies            |
//| With advanced ML integration and institutional-grade features   |
//+------------------------------------------------------------------+

#property copyright "DivineCrush Pro EA"
#property link      "https://yourdomain.com"
#property version   "1.00"
#property description "Advanced EA with Python ML integration and institutional-grade risk management"

// Include professional modules
#include <Includes/AdvancedSignalGenerator.mqh>
#include <Includes/AdvancedRiskManager.mqh>
#include <Includes/PythonSignalIntegrator.mqh>
#include <Includes/SignalFilter.mqh>
#include <Includes/PerformanceTracker.mqh>
#include <Includes/TradeExecutor.mqh>

//+------------------------------------------------------------------+
//| Input Parameters                                                |
//+------------------------------------------------------------------+
input group "=== EA CORE CONFIGURATION ===";
input string EA_Name = "DivineCrushPro";          // EA Identifier
input bool EnableTrading = true;                  // Master trading switch
input int MagicNumber = 202412;                   // Unique magic number

input group "=== TRADING SYMBOLS ===";
input string TradingSymbols = "EURUSD,GBPUSD,XAUUSD";  // Symbols to trade (comma separated)

input group "=== RISK MANAGEMENT ===";
input double RiskPercent = 1.0;                   // Risk per trade (% of balance)
input double MaxDailyLossPercent = 3.0;           // Max daily loss (%)
input double MaxDrawdownPercent = 10.0;           // Max drawdown (%)
input int MaxTradesPerDay = 50;                   // Maximum daily trades
input bool UseKellySizing = true;                 // Use Kelly criterion for position sizing

input group "=== SIGNAL CONFIGURATION ===";
input bool EnablePythonSignals = false;            // Enable Python ML signal integration
input bool EnableAdvancedSignals = true;          // Enable institutional-grade signals
input double MinSignalConfidence = 0.65;          // Minimum confidence threshold
input double MinPythonConfidence = 0.70;          // Minimum Python ML confidence

input group "=== EXECUTION SETTINGS ===";
input int Slippage = 3;                           // Maximum slippage in points
input bool UseDynamicStops = true;                // Use dynamic ATR-based stops
input bool UseImprovedExecution = true;           // Use smart order execution
input int MaxSpread = 20;                         // Maximum allowed spread (points)

input group "=== ADVANCED SETTINGS ===";
input bool EnableMarketRegimeFilter = true;       // Filter by market regime
input bool EnableVolatilityFilter = true;         // Filter by volatility
input bool EnableTimeFilter = true;               // Filter by trading hours
input string TradeStartTime = "08:00";            // Trading start time (Server)
input string TradeEndTime = "16:00";              // Trading end time (Server)

//+------------------------------------------------------------------+
//| Global Variables                                                |
//+------------------------------------------------------------------+
CAdvancedSignalGenerator   *signalGenerator;
CAdvancedRiskManager       *riskManager;
CPythonSignalIntegrator    *pythonIntegrator;
CSignalFilter              *signalFilter;
CPerformanceTracker        *performanceTracker;
CTradeExecutor             *tradeExecutor;

string symbols[];
int dailyTrades = 0;
double dailyPnL = 0;
datetime lastDailyReset = 0;
datetime lastTickProcessed = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("=== DIVINECRUSH PRO EA INITIALIZATION ===");
    
    // Initialize modules
    signalGenerator = new CAdvancedSignalGenerator();
    riskManager = new CAdvancedRiskManager(RiskPercent, MaxDailyLossPercent, MaxDrawdownPercent);
    pythonIntegrator = new CPythonSignalIntegrator();
    signalFilter = new CSignalFilter(EnableMarketRegimeFilter, EnableVolatilityFilter, EnableTimeFilter);
    performanceTracker = new CPerformanceTracker();
    tradeExecutor = new CTradeExecutor(MagicNumber, Slippage, UseImprovedExecution);
    
    // Parse trading symbols
    ParseSymbols(TradingSymbols, symbols);
    
    // Validate symbols
    for(int i = 0; i < ArraySize(symbols); i++)
    {
        if(!SymbolInfoInteger(symbols[i], SYMBOL_SELECT))
        {
            Print("ERROR: Symbol ", symbols[i], " is not available");
            return INIT_FAILED;
        }
        Print("Symbol configured: ", symbols[i]);
    }
    
    // Reset daily counters
    lastDailyReset = iTime(_Symbol, PERIOD_D1, 0);
    dailyTrades = 0;
    dailyPnL = 0;
    
    Print("=== DIVINECRUSH PRO EA READY ===");
    Print("Symbols: ", ArraySize(symbols));
    Print("Risk: ", RiskPercent, "% per trade");
    Print("Max Daily Trades: ", MaxTradesPerDay);
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("=== DIVINECRUSH PRO EA SHUTDOWN ===");
    
    // Clean up modules
    delete signalGenerator;
    delete riskManager;
    delete pythonIntegrator;
    delete signalFilter;
    delete performanceTracker;
    delete tradeExecutor;
    
    Print("EA shutdown complete. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Prevent multiple processing on same tick
    if(lastTickProcessed == iTime(_Symbol, PERIOD_M1, 0)) 
        return;
    lastTickProcessed = iTime(_Symbol, PERIOD_M1, 0);
    
    // Reset daily counters at new day
    if(TimeCurrent() - lastDailyReset >= 86400)
    {
        dailyTrades = 0;
        dailyPnL = 0;
        lastDailyReset = TimeCurrent();
        Print("Daily counters reset. New trading day started.");
    }
    
    // Master trading switch
    if(!EnableTrading)
        return;
    
    // Check if we should trade based on time filter
    if(!IsWithinTradingHours())
        return;
    
    // Process each symbol for trading opportunities
    for(int i = 0; i < ArraySize(symbols); i++)
    {
        ProcessSymbol(symbols[i]);
    }
    
    // Update performance metrics
    performanceTracker.UpdateMetrics();
    
    // Manage existing positions
    ManageOpenPositions();
}

//+------------------------------------------------------------------+
//| Process trading signals for a symbol                            |
//+------------------------------------------------------------------+
void ProcessSymbol(string symbol)
{
    // Skip if already in position for this symbol
    if(tradeExecutor.HasOpenPosition(symbol))
        return;
    
    // Skip if daily trade limit reached
    if(dailyTrades >= MaxTradesPerDay)
        return;
    
    // Skip if spread is too high
    if(!IsSpreadAcceptable(symbol))
        return;
    
    double eaSignal = 0, eaConfidence = 0;
    double pythonSignal = 0, pythonConfidence = 0;
    
    // Generate EA's advanced signals
    if(EnableAdvancedSignals)
    {
        eaSignal = signalGenerator.GenerateEnhancedSignal(symbol);
        eaConfidence = signalGenerator.CalculateSignalConfidence(symbol);
        
        // Log signal generation
        PrintFormat("%s - EA Signal: %.3f, Confidence: %.3f", symbol, eaSignal, eaConfidence);
    }
    
    // Get Python ML signals
    if(EnablePythonSignals)
    {
        if(pythonIntegrator.ReadAndValidatePythonSignal(symbol, pythonSignal, pythonConfidence))
        {
            PrintFormat("%s - Python Signal: %.3f, Confidence: %.3f", symbol, pythonSignal, pythonConfidence);
        }
    }
    
    // Calculate composite signal
    double compositeSignal = CalculateCompositeSignal(eaSignal, eaConfidence, pythonSignal, pythonConfidence);
    double compositeConfidence = CalculateCompositeConfidence(eaConfidence, pythonConfidence);
    
    // Check if signal meets minimum confidence
    if(compositeConfidence < MinSignalConfidence)
        return;
    
    // Check if signal passes all filters
    string direction = compositeSignal > 0 ? "BUY" : "SELL";
    if(!signalFilter.PassesAllFilters(symbol, MathAbs(compositeSignal), direction))
        return;
    
    // Execute the trade
    if(ExecuteTrade(symbol, compositeSignal, compositeConfidence, direction))
    {
        dailyTrades++;
        PrintFormat("TRADE EXECUTED: %s %s (Confidence: %.2f)", symbol, direction, compositeConfidence);
    }
}

//+------------------------------------------------------------------+
//| Calculate composite signal from EA and Python signals           |
//+------------------------------------------------------------------+
double CalculateCompositeSignal(double eaSignal, double eaConfidence, double pythonSignal, double pythonConfidence)
{
    // If Python signal is not available or below threshold, use EA signal only
    if(pythonConfidence < MinPythonConfidence)
        return eaSignal;
    
    // Weight signals based on confidence
    double totalConfidence = eaConfidence + pythonConfidence;
    double eaWeight = eaConfidence / totalConfidence;
    double pythonWeight = pythonConfidence / totalConfidence;
    
    double composite = (eaSignal * eaWeight) + (pythonSignal * pythonWeight);
    
    // Ensure signal is within bounds
    return MathMin(MathMax(composite, -1.0), 1.0);
}

//+------------------------------------------------------------------+
//| Calculate composite confidence                                  |
//+------------------------------------------------------------------+
double CalculateCompositeConfidence(double eaConfidence, double pythonConfidence)
{
    if(pythonConfidence >= MinPythonConfidence)
    {
        // Use weighted average when both signals are available
        return (eaConfidence * 0.4) + (pythonConfidence * 0.6);
    }
    else
    {
        // Use EA confidence only
        return eaConfidence;
    }
}

//+------------------------------------------------------------------+
//| Execute trade with professional risk management                 |
//+------------------------------------------------------------------+
bool ExecuteTrade(string symbol, double signalStrength, double confidence, string direction)
{
    // Calculate optimal position size
    double positionSize = riskManager.CalculateOptimalPositionSize(symbol, MathAbs(signalStrength), confidence);
    
    if(positionSize <= 0)
    {
        Print("ERROR: Invalid position size calculated");
        return false;
    }
    
    // Determine order type
    ENUM_ORDER_TYPE orderType = (direction == "BUY") ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
    
    // Execute trade through professional executor
    bool success = tradeExecutor.ExecuteTrade(symbol, orderType, positionSize, confidence, UseDynamicStops);
    
    if(success)
    {
        // Log successful execution
        PrintFormat("SUCCESS: %s %s %.2f lots (Confidence: %.2f)", 
                   symbol, direction, positionSize, confidence);
    }
    else
    {
        PrintFormat("FAILED: %s trade execution", symbol);
    }
    
    return success;
}

//+------------------------------------------------------------------+
//| Manage open positions (trailing stops, breakeven, etc.)         |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(PositionGetSymbol(i) == "") continue;
        
        string symbol = PositionGetString(POSITION_SYMBOL);
        long magic = PositionGetInteger(POSITION_MAGIC);
        
        // Only manage our EA's positions
        if(magic != MagicNumber) continue;
        
        // Apply trailing stops and breakeven logic
        tradeExecutor.ManagePosition(symbol);
    }
}

//+------------------------------------------------------------------+
//| Check if current time is within trading hours                   |
//+------------------------------------------------------------------+
bool IsWithinTradingHours()
{
    if(!EnableTimeFilter) 
        return true;
    
    MqlDateTime timeNow;
    TimeCurrent(timeNow);
    
    int currentMinutes = timeNow.hour * 60 + timeNow.min;
    int startMinutes = StringToTimeMinutes(TradeStartTime);
    int endMinutes = StringToTimeMinutes(TradeEndTime);
    
    return (currentMinutes >= startMinutes && currentMinutes <= endMinutes);
}

//+------------------------------------------------------------------+
//| Check if spread is acceptable for trading                       |
//+------------------------------------------------------------------+
bool IsSpreadAcceptable(string symbol)
{
    long spread = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
    return (spread <= MaxSpread);
}

//+------------------------------------------------------------------+
//| Parse symbols from input string                                 |
//+------------------------------------------------------------------+
void ParseSymbols(string inputSymbols, string &outputSymbols[])
{
    string tempSymbols[];
    StringSplit(inputSymbols, ',', tempSymbols);
    
    ArrayResize(outputSymbols, ArraySize(tempSymbols));
    for(int i = 0; i < ArraySize(tempSymbols); i++)
    {
        outputSymbols[i] = StringTrim(tempSymbols[i]);
    }
}

//+------------------------------------------------------------------+
//| Convert time string to minutes                                  |
//+------------------------------------------------------------------+
int StringToTimeMinutes(string timeStr)
{
    string parts[];
    StringSplit(timeStr, ':', parts);
    
    if(ArraySize(parts) != 2) 
        return 0;
    
    return StringToInteger(parts[0]) * 60 + StringToInteger(parts[1]);
}

//+------------------------------------------------------------------+
//| Trim string whitespace                                          |
//+------------------------------------------------------------------+
string StringTrim(string str)
{
    StringTrimLeft(str);
    StringTrimRight(str);
    return str;
}