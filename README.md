# FRP Trading System

A high-performance automated trading system that combines OCaml's functional programming strengths with C++'s performance capabilities using Functional Reactive Programming (FRP) principles.

## Architecture

The system is split into two main components:

### OCaml Component
- FRP Framework: Handles asynchronous data streams and event-driven programming
- Strategy Definition Language: DSL for defining trading strategies
- Risk Management Module: Type-safe risk management system

### C++ Component
- Execution Engine: High-speed order execution and matching
- Performance-Critical Algorithms: Optimized implementations of core trading algorithms
- Interoperability Layer: Seamless communication between OCaml and C++ components

## Features

### Execution Engine
- Thread-safe order book management
- Real-time market data simulation
- Position and P&L tracking
- Order matching engine
- Comprehensive callback system for market data and trades

### Order Types
- Market orders
- Limit orders (buy/sell)
- Position tracking
- P&L calculation (realized and unrealized)

### Market Data
- Real-time price updates
- Volume tracking
- Timestamp-based events
- Configurable update frequency

### Thread Safety
- Lock-based synchronization
- Atomic operations
- Thread-safe data structures
- Move semantics optimization

## Prerequisites

### OCaml Requirements
- OCaml (>= 4.13.0)
- dune (build system)
- Core
- Async
- ppx_jane
- ctypes (for C++ bindings)

### C++ Requirements
- C++20 compatible compiler
- CMake (>= 3.15)
- Standard Template Library
- POSIX Threads

## Building the Project

### Building OCaml Component
```bash
cd ocaml
dune build
```

### Building C++ Component
```bash
cd cpp
mkdir build && cd build
cmake ..
make
```

## Testing

### Running C++ Tests
```bash
# Build and run the test executable
cd cpp/build
make
./test_execution
```

The test program provides a visual demonstration of:
- Market data updates
- Order submission and matching
- Position tracking
- P&L calculation
- Real-time trade notifications

Sample output:
```
[Market Data] AAPL @ $100.25 (Vol: 100) 2023-11-15 10:30:45
[Trade] AAPL - Order abc123 @ $100.25 x 50 2023-11-15 10:30:45
[Position] AAPL: 50 @ $100.25 P&L: $0.00 (Unrealized: $12.50)
```

### Running OCaml Tests
```bash
cd ocaml
dune runtest
```

## Project Structure
```
.
├── ocaml/
│   ├── src/           # OCaml source files
│   └── test/          # OCaml test files
└── cpp/
    ├── src/           # C++ source files
    │   ├── execution_engine.cpp    # Core execution engine
    │   └── bindings.cpp           # OCaml bindings
    ├── include/       # C++ header files
    │   ├── execution_engine.hpp    # Engine interface
    │   └── bindings.hpp           # Binding interface
    └── test/          # C++ test files
        └── test_execution.cpp     # Visual test program
```

## Implementation Details

### OrderBook Class
- Thread-safe order management
- Priority queue-based order matching
- Efficient position tracking
- Real-time P&L calculation

### ExecutionEngine Class
- Market data generation and distribution
- Order submission and matching
- Multi-symbol support
- Thread-safe operations

### Binding Layer
- C-style interface for OCaml integration
- Safe memory management
- Callback support for events
- String caching for performance

## Performance Considerations
- Lock-based synchronization for thread safety
- Move semantics for efficient resource management
- Priority queues for order matching
- Optimized memory allocation
- Efficient string handling in bindings

## Future Enhancements
- Advanced order types (Stop, Stop-Limit)
- Historical data storage
- Advanced risk management
- Machine learning integration
- High-frequency trading optimizations
- FIX protocol support

## License
MIT License
