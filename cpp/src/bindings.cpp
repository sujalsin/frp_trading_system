#include "bindings.hpp"
#include "execution_engine.hpp"
#include <memory>
#include <unordered_map>
#include <mutex>

namespace {
    std::unique_ptr<trading::ExecutionEngine> engine;
    std::mutex engine_mutex;
    std::unordered_map<std::string, std::string> string_cache;
    std::mutex cache_mutex;

    const char* cache_string(const std::string& str) {
        std::lock_guard<std::mutex> lock(cache_mutex);
        auto [it, inserted] = string_cache.emplace(str, str);
        return it->first.c_str();
    }
}

extern "C" {

trading::ExecutionEngine* new_execution_engine() {
    std::lock_guard<std::mutex> lock(engine_mutex);
    if (!engine) {
        engine = std::make_unique<trading::ExecutionEngine>();
        engine->start();
    }
    return engine.get();
}

void delete_execution_engine(trading::ExecutionEngine* engine_ptr) {
    std::lock_guard<std::mutex> lock(engine_mutex);
    if (engine && engine.get() == engine_ptr) {
        engine->stop();
        engine.reset();
    }
}

void start_engine(trading::ExecutionEngine* engine_ptr) {
    if (engine_ptr) {
        engine_ptr->start();
    }
}

void stop_engine(trading::ExecutionEngine* engine_ptr) {
    if (engine_ptr) {
        engine_ptr->stop();
    }
}

const char* submit_order(trading::ExecutionEngine* engine_ptr, const char* symbol, double price, int quantity, int side) {
    if (!engine_ptr || !symbol) return nullptr;

    trading::Order order{
        "", // order_id will be generated
        std::string(symbol),
        price,
        quantity,
        side == 0 // 0 for Buy, 1 for Sell
    };

    std::string order_id = engine_ptr->submit_order(order);
    return cache_string(order_id);
}

bool cancel_order(trading::ExecutionEngine* engine_ptr, const char* order_id) {
    // Not implemented yet
    return false;
}

void subscribe_market_data(trading::ExecutionEngine* engine_ptr, const char* symbol, void (*callback)(const trading::MarketData*)) {
    if (!engine_ptr || !symbol || !callback) return;

    engine_ptr->subscribe_market_data(symbol, [callback](const trading::MarketData& data) {
        callback(&data);
    });
}

void subscribe_trades(trading::ExecutionEngine* engine_ptr, const char* symbol, void (*callback)(const trading::Trade*)) {
    if (!engine_ptr || !symbol || !callback) return;

    engine_ptr->subscribe_trades(symbol, [callback](const trading::Trade& trade) {
        callback(&trade);
    });
}

void unsubscribe_market_data(trading::ExecutionEngine* engine_ptr, const char* symbol) {
    if (!engine_ptr || !symbol) return;
    engine_ptr->unsubscribe_market_data(symbol);
}

void unsubscribe_trades(trading::ExecutionEngine* engine_ptr, const char* symbol) {
    if (!engine_ptr || !symbol) return;
    engine_ptr->unsubscribe_trades(symbol);
}

int get_position(trading::ExecutionEngine* engine_ptr, const char* symbol) {
    if (!engine_ptr || !symbol) return 0;
    return engine_ptr->get_position(symbol);
}

double get_average_price(trading::ExecutionEngine* engine_ptr, const char* symbol) {
    if (!engine_ptr || !symbol) return 0.0;
    return engine_ptr->get_average_price(symbol);
}

double get_unrealized_pnl(trading::ExecutionEngine* engine_ptr, const char* symbol) {
    if (!engine_ptr || !symbol) return 0.0;
    return engine_ptr->get_unrealized_pnl(symbol);
}

double get_realized_pnl(trading::ExecutionEngine* engine_ptr, const char* symbol) {
    if (!engine_ptr || !symbol) return 0.0;
    return engine_ptr->get_realized_pnl(symbol);
}

}
