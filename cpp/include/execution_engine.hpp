#pragma once

#include <string>
#include <queue>
#include <mutex>
#include <thread>
#include <atomic>
#include <functional>
#include <unordered_map>
#include <vector>

namespace trading {

struct Order {
    std::string order_id;
    std::string symbol;
    double price;
    int quantity;
    bool is_buy;
};

struct MarketData {
    std::string symbol;
    double price;
    double volume;
    std::string timestamp;
};

struct Trade {
    std::string order_id;
    std::string symbol;
    double price;
    int quantity;
    std::string timestamp;
};

using MarketDataCallback = std::function<void(const MarketData&)>;
using TradeCallback = std::function<void(const Trade&)>;

class OrderBook {
public:
    OrderBook() : position_(0), average_price_(0.0), realized_pnl_(0.0) {}
    explicit OrderBook(const std::string& symbol) 
        : symbol_(symbol), position_(0), average_price_(0.0), realized_pnl_(0.0) {}
    
    // Delete copy operations
    OrderBook(const OrderBook&) = delete;
    OrderBook& operator=(const OrderBook&) = delete;
    
    // Allow move operations
    OrderBook(OrderBook&& other) noexcept
        : symbol_(std::move(other.symbol_)),
          buy_orders(std::move(other.buy_orders)),
          sell_orders(std::move(other.sell_orders)),
          position_(other.position_),
          average_price_(other.average_price_),
          realized_pnl_(other.realized_pnl_) {}
    
    OrderBook& operator=(OrderBook&& other) noexcept {
        if (this != &other) {
            symbol_ = std::move(other.symbol_);
            buy_orders = std::move(other.buy_orders);
            sell_orders = std::move(other.sell_orders);
            position_ = other.position_;
            average_price_ = other.average_price_;
            realized_pnl_ = other.realized_pnl_;
        }
        return *this;
    }

    void add_order(const Order& order);
    double get_best_bid() const;
    double get_best_ask() const;
    int get_position() const;
    double get_average_price() const;
    double get_unrealized_pnl() const;
    double get_realized_pnl() const;

private:
    void match_orders();

    struct OrderCompare {
        bool operator()(const Order& a, const Order& b) const {
            return a.is_buy ? (a.price < b.price) : (a.price > b.price);
        }
    };

    std::string symbol_;
    std::priority_queue<Order, std::vector<Order>, OrderCompare> buy_orders;
    std::priority_queue<Order, std::vector<Order>, OrderCompare> sell_orders;
    int position_;
    double average_price_;
    double realized_pnl_;
    mutable std::mutex book_mutex;
};

class ExecutionEngine {
public:
    ExecutionEngine();
    ~ExecutionEngine();

    // Delete copy operations
    ExecutionEngine(const ExecutionEngine&) = delete;
    ExecutionEngine& operator=(const ExecutionEngine&) = delete;
    
    // Delete move operations since we have a mutex
    ExecutionEngine(ExecutionEngine&&) = delete;
    ExecutionEngine& operator=(ExecutionEngine&&) = delete;

    void start();
    void stop();

    std::string submit_order(const Order& order);
    
    void subscribe_market_data(const std::string& symbol, MarketDataCallback callback);
    void unsubscribe_market_data(const std::string& symbol);
    
    void subscribe_trades(const std::string& symbol, TradeCallback callback);
    void unsubscribe_trades(const std::string& symbol);

    int get_position(const std::string& symbol) const;
    double get_average_price(const std::string& symbol) const;
    double get_unrealized_pnl(const std::string& symbol) const;
    double get_realized_pnl(const std::string& symbol) const;

private:
    void market_data_thread_func();

    std::atomic<bool> running{false};
    std::thread market_data_thread;
    
    std::unordered_map<std::string, OrderBook> order_books;
    std::unordered_map<std::string, std::vector<MarketDataCallback>> market_data_callbacks;
    std::unordered_map<std::string, std::vector<TradeCallback>> trade_callbacks;
    
    mutable std::mutex engine_mutex;
};

} // namespace trading
