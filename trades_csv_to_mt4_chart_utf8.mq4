//+------------------------------------------------------------------+
//|                                     Tipu Signal Plotter FINAL.mq4 |
//|                        Copyright © 2025, GitHub Copilot Assistant |
//|                             Under guidance of Dixit Khosla       |
//+------------------------------------------------------------------+
#property copyright   "Copyright © 2025, GitHub Copilot Assistant"
#property link        "Under guidance of Dixit Khosla"
#property version   "3.00"
#property description "PRODUCTION READY - Tipu Signal Plotter - Complete multi-format CSV trade visualizer"
#property strict
#property indicator_chart_window

// Define LightGoldenrod color if not available in MQL4
#ifndef clrLightGoldenrod
   #define clrLightGoldenrod 0xD2FAFA
#endif

/*
VERSION LOG:
v1.00 (2016) - Original by Kaleem Haider - Basic MQL5 CSV support
v2.00 (2025) - Multi-format CSV support, symbol cleaning, deposit filtering
v3.00 (2025) - PRODUCTION FINAL - Profit/loss colors, smart arrows, professional UI
*/

#include <stdlib.mqh>
#define PipsPoint Get_PipsPoint()

//+------------------------------------------------------------------+
//| Enumeration for CSV Format Types                                |
//+------------------------------------------------------------------+
enum ENUM_CSV_FORMAT
{
   CSV_FORMAT_MQL5 = 0,      // MQL5 Signal Export Format
   CSV_FORMAT_MYFXBLUE = 1,  // MyFXBlue Export Format  
   CSV_FORMAT_FXBLUE = 2,    // FX Blue Export Format
   CSV_FORMAT_UNKNOWN = -1   // Unknown Format
};

//+------------------------------------------------------------------+
//| Structure for History Load
//| Add more if you like more                                        
//+------------------------------------------------------------------+
struct STRUC_History
  {
   datetime          OpenTime,CloseTime;
   string            OrderType,Symbol,Comment;
   double            Lots,OpenPrice,SLPrice,SLPips,TPPrice,TPPips,ClosePrice,Commission,Swap,Profit;
  };
//+------------------------------------------------------------------+
//| used to convert points to pips and viceversa
//+------------------------------------------------------------------+
double Get_PipsPoint()
  {
   double PP=(_Digits==5 || _Digits==3)?_Point*10:_Point;
   return (PP);
  }

input string sFileName="history.csv"; //File Name
input string sFileDirectory=""; //File Directory
input string sDisplay="Display Order------"; //Display Orders
input int iHOffset            = 0;     //Hour Offset
input bool bBuy               = true;  //Buy Orders?
input bool bBuyLimit          = false; //Buy Limit
input bool bBuyStop           = false; //Buy Stop
input bool bSell              = true;  //Sell
input bool bSellLimit         =false;  //Sell Limit
input bool bSellStop=false;  //Sell Stop
input string sColors="Display Order------"; //Colors Settings
input color cBuy=clrBlue;        //Buy Color
input color cBuyLimit=clrAquamarine;   //Buy Limit Color
input color cBuyStop          = clrPurple;   //Buy Limit Color
input color cSell             =clrRed;       //Sell Color
input color cSellLimit=clrOrange;  //Sell Limit Color
input color cSellStop=clrOrangeRed;  //Sell Limit Color
input string sProfitLoss="Profit/Loss Colors------"; //Profit/Loss Color Settings
input color cBuyProfit = clrGreen;      //Buy Profit Color
input color cBuyLoss = clrRed;       //Buy Loss Color  
input color cSellProfit = clrGreen;      //Sell Profit Color
input color cSellLoss = clrRed;     //Sell Loss Color
input color cSL = clrRed;           //SL Color
input color cTP = clrGreen;         //TP Color

STRUC_History tHistory[];

//+------------------------------------------------------------------+
//| Structure to track symbol statistics                            |
//+------------------------------------------------------------------+
struct SymbolStats
{
   string symbol;
   int count;
};

//+------------------------------------------------------------------+
//| Function to clean symbol name by removing broker suffixes       |
//+------------------------------------------------------------------+
string CleanSymbolName(string symbol)
{
   string cleaned = symbol;
   
   // Common MT4 broker suffixes to remove
   string suffixes[] = {".m", ".cash", ".i", ".pro", ".ecn", ".raw", ".mini", 
                        "_m", "_cash", "_i", "_pro", "_ecn", "_raw", "_mini",
                        "m", "i", "pro", "ecn"};
   
   for(int i = 0; i < ArraySize(suffixes); i++)
   {
      // Remove suffix if found at the end
      int pos = StringFind(cleaned, suffixes[i]);
      if(pos > 0 && pos == StringLen(cleaned) - StringLen(suffixes[i]))
      {
         cleaned = StringSubstr(cleaned, 0, pos);
         break; // Only remove one suffix
      }
   }
   
   return cleaned;
}

//+------------------------------------------------------------------+
//| Function to check if entry should be ignored (deposits/demo)    |
//+------------------------------------------------------------------+
bool ShouldIgnoreEntry(string symbol, string comment, string order_type)
{
   string symbol_lower = symbol;
   string comment_lower = comment;
   string type_lower = order_type;
   
   StringToLower(symbol_lower);
   StringToLower(comment_lower);
   StringToLower(type_lower);
   
   // Check for deposit/demo/withdraw indicators in symbol
   if(StringFind(symbol_lower, "deposit") >= 0 || 
      StringFind(symbol_lower, "demo") >= 0 ||
      StringFind(symbol_lower, "balance") >= 0 ||
      StringFind(symbol_lower, "credit") >= 0 ||
      StringFind(symbol_lower, "withdraw") >= 0 ||
      StringFind(symbol_lower, "withdrawal") >= 0)
   {
      return true;
   }
   
   // Check for deposit/demo/withdraw indicators in comment
   if(StringFind(comment_lower, "deposit") >= 0 || 
      StringFind(comment_lower, "demo") >= 0 ||
      StringFind(comment_lower, "balance") >= 0 ||
      StringFind(comment_lower, "credit") >= 0 ||
      StringFind(comment_lower, "withdraw") >= 0 ||
      StringFind(comment_lower, "withdrawal") >= 0)
   {
      return true;
   }
   
   // Check for deposit/demo/withdraw indicators in order type
   if(StringFind(type_lower, "deposit") >= 0 || 
      StringFind(type_lower, "demo") >= 0 ||
      StringFind(type_lower, "balance") >= 0 ||
      StringFind(type_lower, "credit") >= 0 ||
      StringFind(type_lower, "withdraw") >= 0 ||
      StringFind(type_lower, "withdrawal") >= 0)
   {
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Function to detect CSV format based on header                   |
//+------------------------------------------------------------------+
ENUM_CSV_FORMAT DetectCSVFormat(string header_line)
{
   // Remove BOM character if present
   string clean_header = header_line;
   if(StringFind(clean_header, "ï»¿") == 0)
   {
      clean_header = StringSubstr(clean_header, 3);
   }
   
   // Normalize header to lowercase for comparison
   string header_lower = clean_header;
   StringToLower(header_lower);
   
   // Check for MQL5 format (semicolon delimited with specific headers)
   // Original format: time;type;volume;symbol;price;s/l;t/p
   if(StringFind(header_lower, "time;type;volume;symbol;price;s/l;t/p") >= 0)
   {
      return CSV_FORMAT_MQL5;
   }
   
   // New MQL5 Signal format: Time;Type;Volume;Symbol;Price;Volume;Time;Price;Commission;Swap;Profit
   if(StringFind(header_lower, "time;type;volume;symbol;price;volume;time;price;commission;swap;profit") >= 0)
   {
      return CSV_FORMAT_MQL5;
   }
   
   // Check for MyFXBlue format (comma delimited with Tags,Open Date,Close Date...)
   if(StringFind(header_lower, "tags,open date,close date,symbol,action") >= 0)
   {
      return CSV_FORMAT_MYFXBLUE;
   }
   
   // Check for MyFXBook format (comma delimited with Open Date,Close Date,Symbol,Action...)
   if(StringFind(header_lower, "open date,close date,symbol,action,units/lots") >= 0)
   {
      return CSV_FORMAT_MYFXBLUE;
   }
   
   // Check for FX Blue format (has Type,Ticket,Symbol,Lots,Buy/sell...)
   if(StringFind(header_lower, "type,ticket,symbol,lots,buy/sell") >= 0)
   {
      return CSV_FORMAT_FXBLUE;
   }
   
   return CSV_FORMAT_UNKNOWN;
}

//+------------------------------------------------------------------+
//| Function to split string by delimiter                           |
//+------------------------------------------------------------------+
int SplitString(string input_string, string delimiter, string &result[])
{
   ArrayFree(result);
   int pos = 0;
   int next_pos = 0;
   int count = 0;
   
   while(true)
   {
      next_pos = StringFind(input_string, delimiter, pos);
      if(next_pos == -1)
      {
         // Last element
         ArrayResize(result, count + 1);
         result[count] = StringSubstr(input_string, pos);
         count++;
         break;
      }
      else
      {
         ArrayResize(result, count + 1);
         result[count] = StringSubstr(input_string, pos, next_pos - pos);
         count++;
         pos = next_pos + StringLen(delimiter);
      }
   }
   
   return count;
}

//+------------------------------------------------------------------+
//| Function to convert datetime from different formats             |
//+------------------------------------------------------------------+
datetime ConvertDateTime(string date_string, ENUM_CSV_FORMAT format)
{
   datetime result = 0;
   
   switch(format)
   {
      case CSV_FORMAT_MQL5:
         {
            // Format: 2025.08.13 12:26:40
            result = StrToTime(date_string);
            break;
         }
         
      case CSV_FORMAT_MYFXBLUE:
         {
            // Format: 08/14/2025 03:30
            // Convert MM/DD/YYYY HH:MM to YYYY.MM.DD HH:MM
            string parts[];
            SplitString(date_string, " ", parts);
            if(ArraySize(parts) >= 2)
            {
               string date_parts[];
               SplitString(parts[0], "/", date_parts);
               if(ArraySize(date_parts) >= 3)
               {
                  string converted = date_parts[2] + "." + date_parts[0] + "." + date_parts[1] + " " + parts[1];
                  result = StrToTime(converted);
               }
            }
            break;
         }
         
      case CSV_FORMAT_FXBLUE:
         {
            // Format: 2025/08/18 11:00:00
            // Convert YYYY/MM/DD HH:MM:SS to YYYY.MM.DD HH:MM:SS
            StringReplace(date_string, "/", ".");
            result = StrToTime(date_string);
            break;
         }
   }
   
   return result;
}

//+------------------------------------------------------------------+
//| Function to normalize order type                                |
//+------------------------------------------------------------------+
string NormalizeOrderType(string order_type, ENUM_CSV_FORMAT format)
{
   string normalized = order_type;
   StringToUpper(normalized);
   
   switch(format)
   {
      case CSV_FORMAT_MQL5:
         // Already in correct format (Buy, Sell, etc.)
         break;
         
      case CSV_FORMAT_MYFXBLUE:
         // Action field: Buy/Sell
         if(normalized == "BUY") normalized = "Buy";
         else if(normalized == "SELL") normalized = "Sell";
         break;
         
      case CSV_FORMAT_FXBLUE:
         // Buy/sell field: Buy/Sell
         if(normalized == "BUY") normalized = "Buy";
         else if(normalized == "SELL") normalized = "Sell";
         break;
   }
   
   return normalized;
}

//+------------------------------------------------------------------+
//| Function to parse MQL5 format line                              |
//+------------------------------------------------------------------+
bool ParseMQL5Line(string line, STRUC_History &history)
{
   string fields[];
   int field_count = SplitString(line, ";", fields);
   
   // Handle different MQL5 formats
   if(field_count == 11) // New MQL5 Signal format: Time;Type;Volume;Symbol;Price;Volume;Time;Price;Commission;Swap;Profit
   {
      // Check if this is a deposit/demo entry that should be ignored
      if(ShouldIgnoreEntry(fields[3], "", fields[1])) return false;
      
      history.OpenTime = ConvertDateTime(fields[0], CSV_FORMAT_MQL5) + iHOffset*60*60;
      history.OrderType = NormalizeOrderType(fields[1], CSV_FORMAT_MQL5);
      history.Lots = (double)fields[2];
      history.Symbol = fields[3];
      history.OpenPrice = (double)fields[4];
      history.SLPrice = 0.0; // Not available in this format
      history.TPPrice = 0.0; // Not available in this format
      history.CloseTime = ConvertDateTime(fields[6], CSV_FORMAT_MQL5) + iHOffset*60*60;
      history.ClosePrice = (double)fields[7];
      history.Commission = (double)fields[8];
      history.Swap = (double)fields[9];
      history.Profit = (double)fields[10];
      history.Comment = "";
      
      return true;
   }
   else if(field_count >= 13) // Original MQL5 format
   {
      // Check if this is a deposit/demo entry that should be ignored
      if(ShouldIgnoreEntry(fields[3], fields[12], fields[1])) return false;
      
      history.OpenTime = ConvertDateTime(fields[0], CSV_FORMAT_MQL5) + iHOffset*60*60;
      history.OrderType = NormalizeOrderType(fields[1], CSV_FORMAT_MQL5);
      history.Lots = (double)fields[2];
      history.Symbol = fields[3];
      history.OpenPrice = (double)fields[4];
      history.SLPrice = (double)fields[5];
      history.TPPrice = (double)fields[6];
      history.CloseTime = ConvertDateTime(fields[7], CSV_FORMAT_MQL5) + iHOffset*60*60;
      history.ClosePrice = (double)fields[8];
      history.Commission = (double)fields[9];
      history.Swap = (double)fields[10];
      history.Profit = (double)fields[11];
      history.Comment = fields[12];
      
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Function to parse MyFXBlue format line                          |
//+------------------------------------------------------------------+
bool ParseMyFXBlueLine(string line, STRUC_History &history)
{
   string fields[];
   int field_count = SplitString(line, ",", fields);
   
   // Handle different MyFXBlue/MyFXBook formats
   if(field_count >= 25) // New MyFXBook format: Open Date,Close Date,Symbol,Action,Units/Lots,Open Price,Close Price,Commission,Swap,Pips,Profit...
   {
      // Skip empty lines or header-like lines
      if(StringLen(StringTrimLeft(StringTrimRight(fields[0]))) == 0) return false;
      
      // Check if this is a deposit/demo entry that should be ignored
      if(ShouldIgnoreEntry(fields[2], "", fields[3])) return false;
      
      history.OpenTime = ConvertDateTime(fields[0], CSV_FORMAT_MYFXBLUE) + iHOffset*60*60;
      history.CloseTime = ConvertDateTime(fields[1], CSV_FORMAT_MYFXBLUE) + iHOffset*60*60;
      history.Symbol = fields[2];
      history.OrderType = NormalizeOrderType(fields[3], CSV_FORMAT_MYFXBLUE);
      history.Lots = (double)fields[4];
      history.OpenPrice = (double)fields[5];
      history.ClosePrice = (double)fields[6];
      history.Commission = (double)fields[7];
      history.Swap = (double)fields[8];
      history.Profit = (double)fields[10];
      history.SLPrice = 0.0; // Not available in this format
      history.TPPrice = 0.0; // Not available in this format
      history.Comment = "";
      
      return true;
   }
   else if(field_count >= 15) // Original MyFXBlue format
   {
      // Skip empty lines or header-like lines
      if(StringLen(StringTrimLeft(StringTrimRight(fields[1]))) == 0) return false;
      
      // Check if this is a deposit/demo entry that should be ignored
      string comment = (field_count > 15) ? fields[15] : "";
      if(ShouldIgnoreEntry(fields[3], comment, fields[4])) return false;
      
      history.OpenTime = ConvertDateTime(fields[1], CSV_FORMAT_MYFXBLUE) + iHOffset*60*60;
      history.CloseTime = ConvertDateTime(fields[2], CSV_FORMAT_MYFXBLUE) + iHOffset*60*60;
      history.Symbol = fields[3];
      history.OrderType = NormalizeOrderType(fields[4], CSV_FORMAT_MYFXBLUE);
      history.Lots = (double)fields[5];
      history.SLPrice = (double)fields[6];
      history.TPPrice = (double)fields[7];
      history.OpenPrice = (double)fields[8];
      history.ClosePrice = (double)fields[9];
      history.Commission = (double)fields[10];
      history.Swap = (double)fields[11];
      // Pips are in field[12], Profit in field[13]
      history.Profit = (double)fields[13];
      history.Comment = comment;
      
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Function to parse FX Blue format line                           |
//+------------------------------------------------------------------+
bool ParseFXBlueLine(string line, STRUC_History &history)
{
   string fields[];
   int field_count = SplitString(line, ",", fields);
   
   if(field_count < 20) return false;
   
   // Skip deposit, demo, balance entries and only process "Closed position" entries
   if(fields[0] != "Closed position") return false;
   
   // Check if this is a deposit/demo entry that should be ignored
   string symbol = fields[2];
   string comment = (field_count > 22) ? fields[22] : "";
   if(ShouldIgnoreEntry(symbol, comment, fields[0])) return false;
   
   history.Symbol = fields[2];
   history.Lots = (double)fields[3];
   history.OrderType = NormalizeOrderType(fields[4], CSV_FORMAT_FXBLUE);
   history.OpenPrice = (double)fields[5];
   history.ClosePrice = (double)fields[6];
   history.OpenTime = ConvertDateTime(fields[7], CSV_FORMAT_FXBLUE) + iHOffset*60*60;
   history.CloseTime = ConvertDateTime(fields[8], CSV_FORMAT_FXBLUE) + iHOffset*60*60;
   history.Profit = (double)fields[11];
   history.Swap = (double)fields[12];
   history.Commission = (double)fields[13];
   history.TPPrice = (double)fields[15];
   history.SLPrice = (double)fields[16];
   history.Comment = comment;
   
   return true;
}

//+------------------------------------------------------------------+
//| Function to load history from any supported CSV format          |
//+------------------------------------------------------------------+
bool LoadHistoryFromCSV(string file_path)
{
   ArrayFree(tHistory);
   
   int file_handle = FileOpen(file_path, FILE_READ|FILE_TXT);
   if(file_handle == INVALID_HANDLE)
   {
      Print("Failed to open file: " + file_path + " Error: " + (string)GetLastError());
      Comment("ERROR: Failed to open CSV file: " + file_path);
      return false;
   }
   
   // Read first line to detect format
   string first_line = "";
   if(!FileIsEnding(file_handle))
   {
      first_line = FileReadString(file_handle);
   }
   
   // Skip sep= line if it exists (FX Blue format)
   if(StringFind(first_line, "sep=") >= 0)
   {
      if(!FileIsEnding(file_handle))
      {
         first_line = FileReadString(file_handle);
      }
   }
   
   ENUM_CSV_FORMAT format = DetectCSVFormat(first_line);
   
   if(format == CSV_FORMAT_UNKNOWN)
   {
      Print("Unknown CSV format detected. Header: " + first_line);
      Comment("ERROR: Unknown CSV format detected");
      FileClose(file_handle);
      return false;
   }
   
   string format_names[] = {"MQL5 Signal Export", "MyFXBlue Export", "FX Blue Export"};
   Print("Detected CSV format: " + format_names[format]);
   
   // Arrays to track symbol statistics
   SymbolStats symbol_stats[];
   int total_trades = 0;
   int current_symbol_trades = 0;
   string current_chart_symbol = CleanSymbolName(_Symbol);
   
   // Process data lines
   int history_count = 0;
   string line;
   
   while(!FileIsEnding(file_handle))
   {
      line = FileReadString(file_handle);
      if(StringLen(line) == 0) continue;
      
      STRUC_History temp_history;
      bool parsed = false;
      
      switch(format)
      {
         case CSV_FORMAT_MQL5:
            parsed = ParseMQL5Line(line, temp_history);
            break;
         case CSV_FORMAT_MYFXBLUE:
            parsed = ParseMyFXBlueLine(line, temp_history);
            break;
         case CSV_FORMAT_FXBLUE:
            parsed = ParseFXBlueLine(line, temp_history);
            break;
      }
      
      if(parsed)
      {
         // Clean the symbol name
         temp_history.Symbol = CleanSymbolName(temp_history.Symbol);
         
         // Track symbol statistics
         bool found = false;
         for(int j = 0; j < ArraySize(symbol_stats); j++)
         {
            if(symbol_stats[j].symbol == temp_history.Symbol)
            {
               symbol_stats[j].count++;
               found = true;
               break;
            }
         }
         
         if(!found)
         {
            ArrayResize(symbol_stats, ArraySize(symbol_stats) + 1);
            int last_index = ArraySize(symbol_stats) - 1;
            symbol_stats[last_index].symbol = temp_history.Symbol;
            symbol_stats[last_index].count = 1;
         }
         
         // Count trades for current chart symbol
         if(temp_history.Symbol == current_chart_symbol)
         {
            current_symbol_trades++;
         }
         
         ArrayResize(tHistory, history_count + 1);
         tHistory[history_count] = temp_history;
         history_count++;
         total_trades++;
      }
   }
   
   FileClose(file_handle);
   
   // Generate detailed feedback
   string feedback = "TRADE LOADING COMPLETE\n";
   feedback += "File: " + file_path + "\n";
   feedback += "Format: " + format_names[format] + "\n";
   feedback += "Total Trades Loaded: " + (string)total_trades + "\n\n";
   feedback += "BREAKDOWN BY SYMBOL:\n";
   
   for(int i = 0; i < ArraySize(symbol_stats); i++)
   {
      string marker = "";
      if(symbol_stats[i].symbol == current_chart_symbol)
      {
         marker = " <-- CURRENT";
      }
      feedback += symbol_stats[i].symbol + ": " + (string)symbol_stats[i].count + " trades" + marker + "\n";
   }
   
   feedback += "\nChart Symbol: " + current_chart_symbol + "\n";
   feedback += "Trades for Current Symbol: " + (string)current_symbol_trades + "\n";
   
   // Display feedback on chart
   Comment(feedback);
   
   Print("Loaded " + (string)total_trades + " trade records from " + (string)ArraySize(symbol_stats) + " symbols");
   Print("Current chart symbol (" + current_chart_symbol + "): " + (string)current_symbol_trades + " trades");
   
   return true;
}
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   ResetLastError();
   
   // Remove grid from chart for cleaner appearance
   ChartSetInteger(0, CHART_SHOW_GRID, false);
   
   // Disable scroll to end and shift to end for better chart navigation
   ChartSetInteger(0, CHART_AUTOSCROLL, false);
   ChartSetInteger(0, CHART_SHIFT, false);
   
   // Set chart to bar chart mode
   ChartSetInteger(0, CHART_MODE, CHART_BARS);
   
   // Set price color to LightGoldenrod
   ChartSetInteger(0, CHART_COLOR_CHART_UP, clrLightGoldenrod);
   ChartSetInteger(0, CHART_COLOR_CHART_DOWN, clrLightGoldenrod);
   ChartSetInteger(0, CHART_COLOR_CHART_LINE, clrLightGoldenrod);
   
   string file_path = sFileDirectory + "//" + sFileName;
   
   // Load history using the new universal function
   if(!LoadHistoryFromCSV(file_path))
   {
      Print("Failed to load history from: " + file_path);
      Comment("FAILED TO LOAD CSV FILE: " + file_path);
      return(INIT_FAILED);
   }
   
   // Get cleaned current chart symbol for comparison
   string current_chart_symbol = CleanSymbolName(_Symbol);
   int plotted_trades = 0;
   
   // Mark lines on chart for current symbol only
   for(int i = 0; i < ArraySize(tHistory); i++)
   {
      // Compare cleaned symbol names
      if(tHistory[i].Symbol == current_chart_symbol)
      {
         // Calculate pips for display
         double pips_made = ((tHistory[i].Profit) > 0 ? 1 : -1) * MathAbs(tHistory[i].OpenPrice - tHistory[i].ClosePrice) / PipsPoint;
         
         MarkOrders(0, "tHistory" + (string)tHistory[i].OpenTime, 0, tHistory[i].OpenTime,
                   tHistory[i].OpenPrice, tHistory[i].CloseTime, tHistory[i].ClosePrice,
                   tHistory[i].SLPrice, tHistory[i].TPPrice, tHistory[i].OrderType,
                   StringFormat("%.2f lots | P&L: $%.2f | Pips: %+.1f", tHistory[i].Lots, tHistory[i].Profit, pips_made),
                   tHistory[i].Profit, tHistory[i].Lots, pips_made);
         plotted_trades++;
      }
   }
   
   Print("Plotted " + (string)plotted_trades + " trades for symbol: " + current_chart_symbol);
   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // Delete all trade-related objects
   ObjectsDeleteAll(0,"tHistory");
   // Also delete any individual arrow objects that might remain
   int total_objs = ObjectsTotal();
   for(int i = total_objs - 1; i >= 0; i--)
   {
      string obj_name = ObjectName(i);
      if(StringFind(obj_name, "tHistory") >= 0)
      {
         ObjectDelete(obj_name);
      }
   }
   return;
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+ 
//| Create a trend line by the given coordinates                     | 
//+------------------------------------------------------------------+ 
bool MarkOrders(const long            chart_ID=0,// chart's ID 
                const string          name="TrendLine", // line name 
                const int             sub_window=0,     // subwindow index 
                datetime              opentime=0,       // open time
                double                openprice=0,      // open price
                datetime              closetime=0,      // close time
                double                closeprice=0,     // close price
                double                sl=0,             // stop loss
                double                tp=0,             // target profit
                string                type="Buy",       // order type
                string                tooltip="",       // tooltip text
                double                profit=0,         // trade profit for color determination
                double                lots=0,           // lot size
                double                pips=0)           // pips made

  {
   color           clr=clrWhite;
   ENUM_LINE_STYLE style=STYLE_SOLID; // line style - changed to solid for better visibility
   int             width=3;           // line width - made thicker
   bool            back=false;        // in the background 
   bool            selection=false;    // highlight to move 
   bool            ray_right=false;   // line's continuation to the right 
   bool            hidden=true;       // hidden in the object list 
   long            z_order=0;         // priority for mouse click 

   // Determine color based on order type and profit/loss
   bool is_profitable = (profit > 0);
   
   // Clean up the order type string and make comparison case-insensitive
   string clean_type = type;
   StringTrimLeft(clean_type);
   StringTrimRight(clean_type);
   
   // Convert to uppercase for standardized comparison
   string upper_type = clean_type;
   StringToUpper(upper_type);
   
   // Handle both raw CSV format (BUY/SELL) and normalized format (Buy/Sell)
   if(upper_type=="BUY")
   {
      if(!bBuy) return(false);
      clr = is_profitable ? cBuyProfit : cBuyLoss;
      Print("DEBUG: Buy trade - Profitable: ", is_profitable, " Color: ", clr, " Profit: ", profit);
   }
   else if(upper_type=="SELL")
   {
      if(!bSell) return(false);
      clr = is_profitable ? cSellProfit : cSellLoss;
      Print("DEBUG: Sell trade - Profitable: ", is_profitable, " Color: ", clr, " Profit: ", profit);
   }
   else if(upper_type=="BUY LIMIT")
   {
      if(!bBuyLimit) return(false);
      clr = is_profitable ? cBuyProfit : cBuyLoss;
      Print("DEBUG: Buy Limit trade - Profitable: ", is_profitable, " Color: ", clr, " Profit: ", profit);
   }
   else if(upper_type=="BUY STOP")
   {
      if(!bBuyStop) return(false);
      clr = is_profitable ? cBuyProfit : cBuyLoss;
      Print("DEBUG: Buy Stop trade - Profitable: ", is_profitable, " Color: ", clr, " Profit: ", profit);
   }
   else if(upper_type=="SELL LIMIT")
   {
      if(!bSellLimit) return(false);
      clr = is_profitable ? cSellProfit : cSellLoss;
      Print("DEBUG: Sell Limit trade - Profitable: ", is_profitable, " Color: ", clr, " Profit: ", profit);
   }
   else if(upper_type=="SELL STOP")
   {
      if(!bSellStop) return(false);
      clr = is_profitable ? cSellProfit : cSellLoss;
      Print("DEBUG: Sell Stop trade - Profitable: ", is_profitable, " Color: ", clr, " Profit: ", profit);
   }
   else
   {
      // Fallback for unknown order types
      clr = clrWhite;
      Print("WARNING: Unknown order type '", clean_type, "' - using white color. Raw type: '", type, "'");
   }
   
   // Create enhanced tooltips
   string line_tooltip = StringFormat("TRADE LINE | %s %.2f lots | P&L: $%.2f | Pips: %+.1f", 
                                      clean_type, lots, profit, pips);
   string open_tooltip = StringFormat("OPEN | %s %.2f lots @ %.5f | %s", 
                                     clean_type, lots, openprice, TimeToString(opentime));
   string close_tooltip = StringFormat("CLOSE | %s %.2f lots @ %.5f | P&L: $%.2f | %s", 
                                      clean_type, lots, closeprice, profit, TimeToString(closetime));


//--- set anchor points' coordinates if they are not set 
   ChangeTrendEmptyPoints(opentime,openprice,closetime,closeprice);
//--- reset the error value 
   ResetLastError();
   
//--- delete existing objects with same name to avoid error 4200
   ObjectDelete(chart_ID, name);
   ObjectDelete(chart_ID, name+"sl");
   ObjectDelete(chart_ID, name+"tp");
   ObjectDelete(chart_ID, name+"ao");
   ObjectDelete(chart_ID, name+"ac");
   
//--- create a trend line by the given coordinates 
   if(!ObjectCreate(chart_ID,name,OBJ_TREND,sub_window,opentime,openprice,closetime,closeprice))
     {
      Print(__FUNCTION__,
            ": failed to create a trend line! Error code = ",GetLastError());
      return(false);
     }

//--- validate and set color (reduce debug output)
   if(clr == clrNONE || clr == 0)
   {
      Print("WARNING: Invalid color detected for ", clean_type, " trade. Using default colors.");
      clr = is_profitable ? clrLimeGreen : clrRed;  // Use bright default colors
   }
   else if(clr == clrWhite)
   {
      Print("INFO: White color assigned to ", clean_type, " trade - Profit: ", profit);
   }

//trend line
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY_RIGHT,ray_right);
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
   ObjectSetString(chart_ID,name,OBJPROP_TOOLTIP,line_tooltip);

//arrow for stop loss
   if(sl>0)
     {
      ObjectCreate(0,name+"sl",OBJ_ARROW_BUY,0,opentime,sl);
      ObjectSetInteger(chart_ID,name+"sl",OBJPROP_COLOR,cSL);
      ObjectSetInteger(chart_ID,name+"sl",OBJPROP_WIDTH,3);  // Make arrow thicker
      ObjectSet(name+"sl",OBJPROP_ARROWCODE,4);
      ObjectSetString(chart_ID,name+"sl",OBJPROP_TOOLTIP,"STOP LOSS @ " + DoubleToString(sl,_Digits));
     }

//arrow for target profit
   if(tp>0)
     {
      ObjectCreate(0,name+"tp",OBJ_ARROW_BUY,0,opentime,tp);
      ObjectSetInteger(chart_ID,name+"tp",OBJPROP_COLOR,cTP);
      ObjectSetInteger(chart_ID,name+"tp",OBJPROP_WIDTH,3);  // Make arrow thicker
      ObjectSet(name+"tp",OBJPROP_ARROWCODE,4);
      ObjectSetString(chart_ID,name+"tp",OBJPROP_TOOLTIP,"TAKE PROFIT @ " + DoubleToString(tp,_Digits));
     }

   // Determine arrow colors based on trade direction
   // Open arrows: Green for BUY, Red for SELL (trade direction)
   color open_arrow_color = clrLimeGreen; // Default to green for buy
   if(upper_type=="SELL")
   {
      open_arrow_color = clrRed;
   }
   
   // Close arrows: Red for BUY close (SELL action), Blue for SELL close (BUY action)
   color close_arrow_color = clrRed; // BUY trade closes with SELL action (red)
   if(upper_type=="SELL")
   {
      close_arrow_color = clrBlue; // SELL trade closes with BUY action (blue)
   }

//arrow for open
   ObjectCreate(0,name+"ao",OBJ_ARROW_BUY,0,opentime,openprice);
   ObjectSet(name+"ao",OBJPROP_ARROWCODE,2);
   ObjectSetInteger(chart_ID,name+"ao",OBJPROP_COLOR,open_arrow_color);  // Use trade direction color
   ObjectSetInteger(chart_ID,name+"ao",OBJPROP_WIDTH,4);  // Make arrow bigger
   ObjectSetString(chart_ID,name+"ao",OBJPROP_TOOLTIP,open_tooltip);

//arrow for close
   ObjectCreate(0,name+"ac",OBJ_ARROW_BUY,0,closetime,closeprice);
   ObjectSet(name+"ac",OBJPROP_ARROWCODE,3);
   ObjectSetInteger(chart_ID,name+"ac",OBJPROP_COLOR,close_arrow_color);  // Use closing action color
   ObjectSetInteger(chart_ID,name+"ac",OBJPROP_WIDTH,4);  // Make arrow bigger
   ObjectSetString(chart_ID,name+"ac",OBJPROP_TOOLTIP,close_tooltip);

//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Move trend line anchor point                                     | 
//+------------------------------------------------------------------+ 
bool TrendPointChange(const long   chart_ID=0,       // chart's ID 
                      const string name="TrendLine", // line name 
                      const int    point_index=0,    // anchor point index 
                      datetime     time=0,           // anchor point time coordinate 
                      double       price=0)          // anchor point price coordinate 
  {
//--- if point position is not set, move it to the current bar having Bid price 
   if(!time)
      time=TimeCurrent();
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);

   ResetLastError();

   if(!ObjectMove(chart_ID,name,point_index,time,price))
     {
      Print(__FUNCTION__,
            ": failed to move the anchor point! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Check the values of trend line's anchor points and set default   | 
//| values for empty ones                                            | 
//+------------------------------------------------------------------+ 
void ChangeTrendEmptyPoints(datetime &opentime,double &openprice,
                            datetime &closetime,double &closeprice)
  {

   if(!opentime)
      opentime=TimeCurrent();
   if(!openprice)
      openprice=SymbolInfoDouble(Symbol(),SYMBOL_BID);

   if(!closetime)
     {

      datetime temp[10];
      CopyTime(Symbol(),Period(),opentime,10,temp);
      closetime=temp[0];
     }

   if(!closeprice)
      closeprice=openprice;
  }
//+------------------------------------------------------------------+
