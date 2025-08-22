#!/usr/bin/env python3
"""
Simple test to validate the CleanSymbolName functionality
This simulates what the MQL4 function should do
"""

def clean_symbol_name(symbol):
    """Python equivalent of the CleanSymbolName MQL4 function"""
    if not symbol:
        return symbol
    
    cleaned = symbol.strip().upper()
    
    # Extended list of common MT4 broker suffixes to remove
    suffixes = [".M", ".CASH", ".I", ".PRO", ".ECN", ".RAW", ".MINI", ".FX", ".SPOT",
                "_M", "_CASH", "_I", "_PRO", "_ECN", "_RAW", "_MINI", "_FX", "_SPOT",
                "-M", "-CASH", "-I", "-PRO", "-ECN", "-RAW", "-MINI", "-FX", "-SPOT",
                "M", "I", "PRO", "ECN", "FX", "C"]
    
    # Remove suffixes that appear at the end of the symbol name
    for suffix in suffixes:
        if len(cleaned) > len(suffix) and cleaned.endswith(suffix):
            cleaned = cleaned[:-len(suffix)]
            break  # Only remove one suffix to avoid over-cleaning
    
    # Additional cleanup: remove trailing dots or underscores that might remain
    while cleaned and cleaned[-1] in '._.':
        cleaned = cleaned[:-1]
    
    return cleaned

# Test cases
test_symbols = [
    "EURUSD.m",
    "GBPUSD_ecn", 
    "USDJPY.pro",
    "EURUSD.cash",
    "GBPUSD-raw",
    "AUDUSD_mini",
    "NZDUSD.spot",
    "EURJPY_fx",
    "EURUSD",  # Should remain unchanged
    "GOLD.i",
    "XAUUSD_pro",
    ""  # Edge case: empty string
]

print("Symbol Cleaning Test Results:")
print("=" * 40)
for symbol in test_symbols:
    cleaned = clean_symbol_name(symbol)
    status = "✓" if symbol != cleaned else "→"
    print(f"{status} '{symbol}' → '{cleaned}'")

print("\nExpected behavior:")
print("- Broker suffixes should be removed")
print("- Symbols should be converted to uppercase")
print("- Original symbols without suffixes should remain unchanged")