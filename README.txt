CSV TO MT4 CHART VISUALIZER
==========================

Professional MT4 indicator for visualizing trade history from CSV files or directly from MT4 terminal

FEATURES
--------
- LOCAL TRADES MODE: Direct MT4 terminal history integration (NEW!)
- Multi-format CSV support: MQL5 Signal Export, MyFXBlue, FX Blue
- Smart color coding: Profit/loss visualization with configurable colors
- Professional arrows: Buy/Sell entry and exit markers
- Symbol filtering: Auto-detects and plots only current chart symbol
- Date range filtering: Filter trades by custom date ranges
- Clean visuals: Bar chart mode with enhanced appearance

QUICK START
-----------
CSV MODE (Traditional):
1. Copy trades_csv_to_mt4_chart.mq4 to your MT4 Indicators folder
2. Place your CSV file in MT4 Files folder as trades.csv
3. Restart MT4 and attach indicator to any chart
4. Configure colors and filters in indicator settings

LOCAL TRADES MODE (NEW):
1. Copy trades_csv_to_mt4_chart.mq4 to your MT4 Indicators folder
2. Restart MT4 and attach indicator to any chart
3. In indicator settings, set "Use Local MT4 Trades" to true
4. Configure date range and symbol filters as needed

VISUAL LEGEND
-------------
Green Arrow    = BUY trade entry
Red Arrow      = SELL trade entry / BUY trade exit
Blue Arrow     = SELL trade exit
Line Colors    = Green/Blue = Profit, Red/Orange = Loss

SETTINGS
--------
DATA SOURCE SETTINGS:
- Use Local MT4 Trades: Toggle between CSV and Local mode
- History Days: Number of days to load (0 = all history)
- Current Chart Symbol Only: Filter to current chart symbol
- Start Date / End Date: Custom date range filtering

TRADE FILTERS:
- Show/hide specific order types (Buy, Sell, Limits, Stops)
- Profit/Loss Colors: Customize visualization colors

CSV FILE SETTINGS:
- File Settings: Change CSV filename and directory

CSV FORMAT SUPPORT
------------------
- MQL5 Signal Export (tab-delimited)
- MyFXBlue Export (comma-delimited)  
- FX Blue Export (comma-delimited)

LOCAL TRADES MODE BENEFITS
--------------------------
- Real-time Integration: Direct MT4 terminal access
- Automatic Updates: No manual CSV export needed
- Reduced Workflow: One-click trade history visualization
- Data Integrity: Direct access ensures accuracy
- User Convenience: Eliminates export/import steps

VERSION
-------
v3.1 - Local Trades Mode Integration
Added direct MT4 terminal history support with advanced filtering
Enhanced by GitHub Copilot Assistant under guidance of Dixit Khosla

Ready for live trading analysis and backtesting visualization
