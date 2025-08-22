CSV TO MT4 CHART VISUALIZER
==========================

Professional MT4 indicator for visualizing trade history from CSV files

FEATURES
--------
- Multi-format CSV support: MQL5 Signal Export, MyFXBlue, FX Blue
- Smart symbol cleaning: Automatically removes broker suffixes (.m, .cash, .i, etc.)
- Detailed loading statistics: Shows trades loaded per symbol with chart feedback
- Smart color coding: Profit/loss visualization with configurable colors
- Professional arrows: Buy/Sell entry and exit markers
- Symbol filtering: Auto-detects and plots only current chart symbol
- Clean visuals: Bar chart mode with enhanced appearance

ENHANCED FEATURES (v3.1)
------------------------
- Advanced symbol suffix removal (handles .m, .cash, .i, .pro, .ecn, .raw, .mini, etc.)
- Real-time loading feedback: "Loaded 10/50 trades. 30 for EURUSD, 20 for GBPUSD"
- Symbol statistics displayed on chart with current symbol highlighting
- Debug information for symbol cleaning process
- Enhanced console logging with detailed breakdowns

QUICK START
-----------
1. Copy trades_csv_to_mt4_chart.mq4 to your MT4 Indicators folder
2. Place your CSV file in MT4 Files folder as history.csv (or configure filename)
3. Restart MT4 and attach indicator to any chart
4. View detailed loading statistics in chart comments and console

VISUAL LEGEND
-------------
Green Arrow    = BUY trade entry
Red Arrow      = SELL trade entry / BUY trade exit
Blue Arrow     = SELL trade exit
Line Colors    = Green/Blue = Profit, Red/Orange = Loss

SETTINGS
--------
- Trade Filters: Show/hide specific order types
- Profit/Loss Colors: Customize visualization colors
- File Settings: Change CSV filename and directory

CSV FORMAT SUPPORT
------------------
- MQL5 Signal Export (semicolon-delimited)
- MyFXBlue Export (comma-delimited)  
- FX Blue Export (comma-delimited)

The indicator automatically detects the CSV format and applies appropriate parsing.

SYMBOL CLEANING
---------------
Automatically removes common broker suffixes:
- Dot suffixes: .m, .cash, .i, .pro, .ecn, .raw, .mini, .fx, .spot
- Underscore suffixes: _m, _cash, _i, _pro, _ecn, _raw, _mini, _fx, _spot  
- Dash suffixes: -m, -cash, -i, -pro, -ecn, -raw, -mini, -fx, -spot
- Single character suffixes: m, i, pro, ecn, fx, c

Example: EURUSD.m → EURUSD, GBPUSD_ecn → GBPUSD

VERSION
-------
v3.1 - Enhanced Symbol Processing & Feedback
Enhanced by GitHub Copilot Assistant under guidance of Manthan Khosla

Ready for live trading analysis and backtesting visualization
