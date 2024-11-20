#include "execution_engine.hpp"
#include <chrono>
#include <sstream>
#include <iomanip>
#include <thread>
#include <random>

namespace trading {

namespace {
class MarketDataGenerator {
public:
    MarketDataGenerator() : symbol_(""), price_(100.0), 
        gen_(std::random_device()()), dist_(-1.0, 1.0) {}
        
    MarketDataGenerator(const std::string& symbol, double initial_price = 100.0)
        : symbol_(symbol), price_(initial_price),
          gen_(std::random_device()()), dist_(-1.0, 1.0) {}

    MarketData generate() {
        double change = dist_(gen_);
        price_ *= (1.0 + change * 0.01); // Max 1% price change

        auto now = std::chrono::system_clock::now();
        auto now_c = std::chrono::system_clock::to_time_t(now);
        std::stringstream ss;
        ss << std::put_time(std::localtime(&now_c), "%Y-%m-%d %H:%M:%S");

        return MarketData{
            symbol_,
            price_,
            100.0, // Fixed volume for simplicity
            ss.str()
        };
    }

private:
    std::string symbol_;
    double price_;
    std::mt19937 gen_;
    std::uniform_real_distribution<> dist_;
};

std::string generate_order_id() {
    static std::random_device rd;
    static std::mt19937 gen(rd());
    static std::uniform_int_distribution<> dis(0, 15);
    static const char* digits = "0123456789abcdef";

    std::string uuid;
    uuid.reserve(36);

    for (int i = 0; i < 36; i++) {
        if (i == 8 || i == 13 || i == 18 || i == 23) {
            uuid += '-';
        } else {
            uuid += digits[dis(gen)];
        }
    }
    return uuid;
}

} // anonymous namespace

void OrderBook::add_order(const Order& order) {
    std::lock_guard<std::mutex> lock(book_mutex);
    if (order.is_buy) {
        buy_orders.push(order);
    } else {
        sell_orders.push(order);
    }
    match_orders();
}

void OrderBook::match_orders() {
    while (!buy_orders.empty() && !sell_orders.empty()) {
        auto& buy = buy_orders.top();
        auto& sell = sell_orders.top();
        
        if (buy.price >= sell.price) {
            int matched_quantity = std::min(buy.quantity, sell.quantity);
            double matched_price = (buy.price + sell.price) / 2.0;
            
            // Update position and P&L
            if (buy.quantity == matched_quantity) {
                buy_orders.pop();
            } else {
                const_cast<Order&>(buy).quantity -= matched_quantity;
            }
            
            if (sell.quantity == matched_quantity) {
                sell_orders.pop();
            } else {
                const_cast<Order&>(sell).quantity -= matched_quantity;
            }
            
            position_ += matched_quantity;
            double old_value = average_price_ * position_;
            double new_value = matched_price * matched_quantity;
            average_price_ = (old_value + new_value) / (position_ + matched_quantity);
            
            // Calculate realized P&L
            realized_pnl_ += (matched_price - average_price_) * matched_quantity;
        } else {
            break;
        }
    }
}

double OrderBook::get_best_bid() const {
    std::lock_guard<std::mutex> lock(book_mutex);
    return buy_orders.empty() ? 0.0 : buy_orders.top().price;
}

double OrderBook::get_best_ask() const {
    std::lock_guard<std::mutex> lock(book_mutex);
    return sell_orders.empty() ? 0.0 : sell_orders.top().price;
}

int OrderBook::get_position() const {
    std::lock_guard<std::mutex> lock(book_mutex);
    return position_;
}

double OrderBook::get_average_price() const {
    std::lock_guard<std::mutex> lock(book_mutex);
    return average_price_;
}

double OrderBook::get_unrealized_pnl() const {
    std::lock_guard<std::mutex> lock(book_mutex);
    double mid_price = (get_best_bid() + get_best_ask()) / 2.0;
    return position_ * (mid_price - average_price_);
}

double OrderBook::get_realized_pnl() const {
    std::lock_guard<std::mutex> lock(book_mutex);
    return realized_pnl_;
}

ExecutionEngine::ExecutionEngine() = default;

ExecutionEngine::~ExecutionEngine() {
    stop();
}

void ExecutionEngine::start() {
    running = true;
    market_data_thread = std::thread(&ExecutionEngine::market_data_thread_func, this);
}

void ExecutionEngine::stop() {
    if (running.exchange(false) && market_data_thread.joinable()) {
        market_data_thread.join();
    }
}

void ExecutionEngine::market_data_thread_func() {
    std::unordered_map<std::string, MarketDataGenerator> generators;
    
    while (running) {
        {
            std::lock_guard<std::mutex> lock(engine_mutex);
            for (const auto& [symbol, callbacks] : market_data_callbacks) {
                if (generators.find(symbol) == generators.end()) {
                    generators.emplace(symbol, MarketDataGenerator(symbol));
                }
                auto data = generators[symbol].generate();
                for (const auto& callback : callbacks) {
                    callback(data);
                }
            }
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
}

std::string ExecutionEngine::submit_order(const Order& order) {
    std::lock_guard<std::mutex> lock(engine_mutex);

    // Create order book if it doesn't exist
    auto [it, inserted] = order_books.try_emplace(order.symbol, OrderBook(order.symbol));

    // Generate order ID and submit order
    Order order_with_id = order;
    order_with_id.order_id = generate_order_id();
    
    it->second.add_order(order_with_id);
    
    return order_with_id.order_id;
}

void ExecutionEngine::subscribe_market_data(const std::string& symbol, MarketDataCallback callback) {
    std::lock_guard<std::mutex> lock(engine_mutex);
    market_data_callbacks[symbol].push_back(callback);
}

void ExecutionEngine::unsubscribe_market_data(const std::string& symbol) {
    std::lock_guard<std::mutex> lock(engine_mutex);
    market_data_callbacks.erase(symbol);
}

void ExecutionEngine::subscribe_trades(const std::string& symbol, TradeCallback callback) {
    std::lock_guard<std::mutex> lock(engine_mutex);
    trade_callbacks[symbol].push_back(callback);
}

void ExecutionEngine::unsubscribe_trades(const std::string& symbol) {
    std::lock_guard<std::mutex> lock(engine_mutex);
    trade_callbacks.erase(symbol);
}

int ExecutionEngine::get_position(const std::string& symbol) const {
    std::lock_guard<std::mutex> lock(engine_mutex);
    auto it = order_books.find(symbol);
    return it != order_books.end() ? it->second.get_position() : 0;
}

double ExecutionEngine::get_average_price(const std::string& symbol) const {
    std::lock_guard<std::mutex> lock(engine_mutex);
    auto it = order_books.find(symbol);
    return it != order_books.end() ? it->second.get_average_price() : 0.0;
}

double ExecutionEngine::get_unrealized_pnl(const std::string& symbol) const {
    std::lock_guard<std::mutex> lock(engine_mutex);
    auto it = order_books.find(symbol);
    return it != order_books.end() ? it->second.get_unrealized_pnl() : 0.0;
}

double ExecutionEngine::get_realized_pnl(const std::string& symbol) const {
    std::lock_guard<std::mutex> lock(engine_mutex);
    auto it = order_books.find(symbol);
    return it != order_books.end() ? it->second.get_realized_pnl() : 0.0;
}

} // namespace trading
