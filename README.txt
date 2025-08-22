CSV TO MT4 CHART VISUALIZER
==========================

Professional MT4 indicator for visualizing trade history from CSV files or directly from MT4 terminal

FEATURES
--------
- Dual mode support: CSV import OR direct MT4 history reading
- Multi-format CSV support: MQL5 Signal Export, MyFXBlue, FX Blue
- Local Trades Mode: Direct access to MT4 terminal trade history
- Smart color coding: Profit/loss visualization with configurable colors
- Professional arrows: Buy/Sell entry and exit markers
- Symbol filtering: Auto-detects and plots only current chart symbol
- Advanced filtering: Date ranges, history days, symbol selection
- Clean visuals: Bar chart mode with enhanced appearance

QUICK START
-----------
CSV MODE:
1. Copy trades_csv_to_mt4_chart.mq4 to your MT4 Indicators folder
2. Place your CSV file in MT4 Files folder as trades.csv
3. Restart MT4 and attach indicator to any chart
4. Configure colors and filters in indicator settings

LOCAL TRADES MODE:
1. Copy trades_csv_to_mt4_chart.mq4 to your MT4 Indicators folder
2. Restart MT4 and attach indicator to any chart
3. In indicator settings, enable "Local Trades Mode"
4. Configure history days, symbol filters, and date ranges
5. Indicator automatically reads from MT4 terminal history

VISUAL LEGEND
-------------
Green Arrow    = BUY trade entry
Red Arrow      = SELL trade entry / BUY trade exit
Blue Arrow     = SELL trade exit
Line Colors    = Green/Blue = Profit, Red/Orange = Loss

SETTINGS
--------
DATA SOURCE SELECTION:
- Enable Local Trades Mode: Switch between CSV and MT4 history
- Local Mode Info: Instructions for local mode

LOCAL TRADES SETTINGS:
- History Days: Number of days to load (0 = all history)
- Current Symbol Only: Filter to show only current chart symbol
- Start Date: Custom start date for filtering (0 = auto)
- End Date: Custom end date for filtering (0 = current time)

OTHER SETTINGS:
- Trade Filters: Show/hide specific order types
- Profit/Loss Colors: Customize visualization colors
- File Settings: Change CSV filename and directory (CSV mode only)

CSV FORMAT SUPPORT
------------------
- MQL5 Signal Export (tab-delimited)
- MyFXBlue Export (comma-delimited)  
- FX Blue Export (comma-delimited)

LOCAL TRADES MODE
-----------------
- Reads directly from MT4 OrdersHistory()
- Supports all closed order types (Buy, Sell, Limits, Stops)
- Applies same filtering as CSV mode (deposits, withdrawals)
- Real-time access to MT4 terminal data
- No CSV export required

VERSION
-------
v3.1 - Local Trades Mode
Added direct MT4 history integration with advanced filtering
Enhanced by GitHub Copilot Assistant under guidance of Dixit Khosla

Ready for live trading analysis and backtesting visualization
