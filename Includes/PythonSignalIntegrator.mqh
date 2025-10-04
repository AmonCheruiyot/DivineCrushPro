//+------------------------------------------------------------------+
//| PythonSignalIntegrator.mqh                                      |
//| Python ML signal integration and validation                    |
//+------------------------------------------------------------------+

class CPythonSignalIntegrator
{
private:
    string m_dataPath;
    
public:
    CPythonSignalIntegrator();
    bool ReadAndValidatePythonSignal(string symbol, double &signal, double &confidence);
    bool IsSignalFresh(datetime signalTime);
};

//+------------------------------------------------------------------+
//| Constructor                                                     |
//+------------------------------------------------------------------+
CPythonSignalIntegrator::CPythonSignalIntegrator()
{
    m_dataPath = "DivineCrushPro/";
}

//+------------------------------------------------------------------+
//| Read and validate Python ML signal                             |
//+------------------------------------------------------------------+
bool CPythonSignalIntegrator::ReadAndValidatePythonSignal(string symbol, double &signal, double &confidence)
{
    string filename = m_dataPath + "python_signals_" + symbol + ".csv";
    
    int fileHandle = FileOpen(filename, FILE_READ|FILE_CSV|FILE_ANSI, ',');
    if(fileHandle == INVALID_HANDLE)
    {
        // Print("No Python signal file found: ", filename);
        return false;
    }
    
    // Read the latest signal (first line)
    if(FileIsEnding(fileHandle))
    {
        FileClose(fileHandle);
        return false;
    }
    
    string timestampStr = FileReadString(fileHandle);
    string symbolStr = FileReadString(fileHandle);
    string signalStr = FileReadString(fileHandle);
    string confidenceStr = FileReadString(fileHandle);
    
    FileClose(fileHandle);
    
    // Validate data
    if(StringLen(timestampStr) == 0 || StringLen(signalStr) == 0 || StringLen(confidenceStr) == 0)
        return false;
    
    // Parse values
    datetime signalTime = (datetime)StringToInteger(timestampStr);
    signal = StringToDouble(signalStr);
    confidence = StringToDouble(confidenceStr);
    
    // Validate signal freshness (max 5 minutes old)
    if(!IsSignalFresh(signalTime))
        return false;
    
    // Validate confidence threshold
    if(confidence < 0.1 || confidence > 1.0)
        return false;
    
    // Validate signal range
    if(signal < -1.0 || signal > 1.0)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Check if signal is fresh (within 5 minutes)                    |
//+------------------------------------------------------------------+
bool CPythonSignalIntegrator::IsSignalFresh(datetime signalTime)
{
    return (TimeCurrent() - signalTime <= 300); // 5 minutes
}