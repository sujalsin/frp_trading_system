#pragma once

#include "execution_engine.hpp"
#include <memory>

extern "C" {
    // Engine management
    trading::ExecutionEngine* new_execution_engine();
    void delete_execution_engine(trading::ExecutionEngine* engine);
    void start_engine(trading::ExecutionEngine* engine);
    void stop_engine(trading::ExecutionEngine* engine);

    // Order management
    const char* submit_order(
        trading::ExecutionEngine* engine,
        const char* symbol,
        double price,
        int quantity,
        int side  // 0 for Buy, 1 for Sell
    );

    bool cancel_order(
        trading::ExecutionEngine* engine,
        const char* order_id
    );

    // Position information
    int get_position(
        trading::ExecutionEngine* engine,
        const char* symbol
    );

    double get_average_price(
        trading::ExecutionEngine* engine,
        const char* symbol
    );

    double get_unrealized_pnl(
        trading::ExecutionEngine* engine,
        const char* symbol
    );

    double get_realized_pnl(
        trading::ExecutionEngine* engine,
        const char* symbol
    );

    // Market data subscription
    void subscribe_market_data(
        trading::ExecutionEngine* engine,
        const char* symbol,
        void (*callback)(const trading::MarketData*)
    );

    void unsubscribe_market_data(
        trading::ExecutionEngine* engine,
        const char* symbol
    );

    // Trade subscription
    void subscribe_trades(
        trading::ExecutionEngine* engine,
        const char* symbol,
        void (*callback)(const trading::Trade*)
    );

    void unsubscribe_trades(
        trading::ExecutionEngine* engine,
        const char* symbol
    );
}
