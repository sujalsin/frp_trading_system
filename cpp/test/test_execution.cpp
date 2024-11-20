#include "execution_engine.hpp"
#include <iostream>
#include <iomanip>
#include <thread>
#include <chrono>
#include <vector>
#include <sstream>
#include <random>

// ANSI color codes for prettier output
namespace Color {
    const char* Reset   = "\033[0m";
    const char* Red     = "\033[31m";
    const char* Green   = "\033[32m";
    const char* Yellow  = "\033[33m";
    const char* Blue    = "\033[34m";
    const char* Magenta = "\033[35m";
}

void display_position(const std::string& symbol, const trading::ExecutionEngine& engine) {
    std::cout << Color::Yellow << "[Position] " << Color::Reset
              << symbol << ": " << engine.get_position(symbol)
              << " @ $" << std::fixed << std::setprecision(2) << engine.get_average_price(symbol)
              << " P&L: $" << engine.get_realized_pnl(symbol) 
              << " (Unrealized: $" << engine.get_unrealized_pnl(symbol) << ")"
              << std::endl;
}

int main() {
    std::cout << "Starting Execution Engine Test...\n" << std::endl;

    trading::ExecutionEngine engine;
    std::cout << "Created engine\n";
    
    engine.start();
    std::cout << "Started engine\n";

    const std::string symbol = "AAPL";
    std::cout << "Testing with symbol: " << symbol << std::endl;

    // Subscribe to market data and trades
    engine.subscribe_market_data(symbol, 
        [](const trading::MarketData& data) {
            std::cout << Color::Blue << "[Market] " << Color::Reset
                      << data.symbol << " @ $" << std::fixed << std::setprecision(2) 
                      << data.price << std::endl;
        }
    );

    engine.subscribe_trades(symbol,
        [](const trading::Trade& trade) {
            std::cout << Color::Green << "[Trade] " << Color::Reset
                      << trade.symbol << " @ $" << std::fixed << std::setprecision(2) 
                      << trade.price << " x " << trade.quantity << std::endl;
        }
    );

    std::cout << "\nStarting Position:\n";
    display_position(symbol, engine);

    // First trade: Buy 100 shares at $100
    std::cout << "\nSubmitting buy order (100 shares @ $100.00)...\n";
    trading::Order buy_order{
        "", 
        symbol,
        100.0,
        100,
        true
    };
    engine.submit_order(buy_order);
    
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    std::cout << "\nPosition after buy:\n";
    display_position(symbol, engine);

    // Second trade: Sell 50 shares at $105
    std::cout << "\nSubmitting sell order (50 shares @ $105.00)...\n";
    trading::Order sell_order1{
        "",
        symbol,
        105.0,
        50,
        false
    };
    engine.submit_order(sell_order1);
    
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    std::cout << "\nPosition after partial sell:\n";
    display_position(symbol, engine);

    // Third trade: Sell remaining 50 shares at $110
    std::cout << "\nSubmitting sell order (50 shares @ $110.00)...\n";
    trading::Order sell_order2{
        "",
        symbol,
        110.0,
        50,
        false
    };
    engine.submit_order(sell_order2);
    
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    std::cout << "\nFinal Position:\n";
    display_position(symbol, engine);

    std::cout << "\nStopping engine...\n";
    engine.stop();
    std::cout << "Test completed.\n" << std::endl;

    return 0;
}
