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
    const char* Cyan    = "\033[36m";
}

class OrderBookVisualizer {
public:
    static void displayMarketData(const trading::MarketData& data) {
        std::cout << Color::Blue << "[Market Data] " << Color::Reset
                  << data.symbol << " @ $" << std::fixed << std::setprecision(2) 
                  << data.price << " (Vol: " << data.volume << ") "
                  << data.timestamp << std::endl;
    }

    static void displayTrade(const trading::Trade& trade) {
        std::cout << Color::Green << "[Trade] " << Color::Reset
                  << trade.symbol << " - Order " << trade.order_id 
                  << " @ $" << std::fixed << std::setprecision(2) << trade.price
                  << " x " << trade.quantity << " " << trade.timestamp << std::endl;
    }

    static void displayPosition(const std::string& symbol, const trading::ExecutionEngine& engine) {
        std::cout << Color::Yellow << "[Position] " << Color::Reset
                  << symbol << ": " << engine.get_position(symbol)
                  << " @ $" << std::fixed << std::setprecision(2) << engine.get_average_price(symbol)
                  << " P&L: $" << engine.get_realized_pnl(symbol)
                  << " (Unrealized: $" << engine.get_unrealized_pnl(symbol) << ")"
                  << std::endl;
    }

    static void displayOrderBook(const std::string& symbol, const trading::ExecutionEngine& engine) {
        std::cout << Color::Magenta << "[OrderBook] " << Color::Reset
                  << symbol << " - Best Bid: $" << std::fixed << std::setprecision(2)
                  << "TODO" // TODO: Add best bid/ask display
                  << " Best Ask: $" << "TODO"
                  << std::endl;
    }
};

int main() {
    std::cout << "Starting Execution Engine Test...\n" << std::endl;

    // Create and start the execution engine
    trading::ExecutionEngine engine;
    engine.start();

    // Test symbols
    const std::string symbols[] = {"AAPL", "GOOGL", "MSFT"};

    // Subscribe to market data for all symbols
    for (const auto& symbol : symbols) {
        engine.subscribe_market_data(symbol, 
            [](const trading::MarketData& data) {
                OrderBookVisualizer::displayMarketData(data);
            }
        );

        engine.subscribe_trades(symbol,
            [](const trading::Trade& trade) {
                OrderBookVisualizer::displayTrade(trade);
            }
        );
    }

    // Function to submit random orders
    auto submit_random_orders = [&](const std::string& symbol) {
        std::random_device rd;
        std::mt19937 gen(rd());
        std::uniform_real_distribution<> price_dist(90.0, 110.0);
        std::uniform_int_distribution<> qty_dist(1, 100);
        std::uniform_int_distribution<> side_dist(0, 1);

        for (int i = 0; i < 5; ++i) {
            trading::Order order{
                "", // order_id will be generated
                symbol,
                price_dist(gen),
                qty_dist(gen),
                side_dist(gen) == 0
            };

            engine.submit_order(order);
            std::this_thread::sleep_for(std::chrono::milliseconds(500));
        }
    };

    // Submit orders for each symbol
    std::cout << "\nSubmitting orders...\n" << std::endl;
    for (const auto& symbol : symbols) {
        submit_random_orders(symbol);
        OrderBookVisualizer::displayPosition(symbol, engine);
        OrderBookVisualizer::displayOrderBook(symbol, engine);
        std::cout << std::endl;
    }

    // Let the market data and trades process
    std::this_thread::sleep_for(std::chrono::seconds(5));

    // Display final positions
    std::cout << "\nFinal Positions:\n" << std::endl;
    for (const auto& symbol : symbols) {
        OrderBookVisualizer::displayPosition(symbol, engine);
    }

    // Stop the engine
    engine.stop();
    std::cout << "\nTest completed.\n" << std::endl;

    return 0;
}
