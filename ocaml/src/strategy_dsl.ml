open Core
open Async
open Frp

(* Strategy DSL types *)
type condition =
  | Price_above of float
  | Price_below of float
  | Volume_above of int
  | Volume_below of int
  | And of condition * condition
  | Or of condition * condition
  | Not of condition

type action =
  | Buy of int  (* quantity *)
  | Sell of int (* quantity *)
  | Cancel_all

type rule = {
  symbol: string;
  condition: condition;
  action: action;
}

type strategy = {
  name: string;
  rules: rule list;
  risk_params: Risk.t;
}

(* DSL evaluation *)
let rec eval_condition market_data condition =
  match condition with
  | Price_above price -> market_data.price > price
  | Price_below price -> market_data.price < price
  | Volume_above vol -> market_data.quantity > vol
  | Volume_below vol -> market_data.quantity < vol
  | And (c1, c2) -> eval_condition market_data c1 && eval_condition market_data c2
  | Or (c1, c2) -> eval_condition market_data c1 || eval_condition market_data c2
  | Not c -> not (eval_condition market_data c)

(* Strategy execution *)
let execute_strategy (engine: Bindings.Engine.t) (strategy: strategy) market_data_stream =
  let execute_rule rule market_data =
    if eval_condition market_data rule.condition then
      match rule.action with
      | Buy quantity ->
          let order = {
            symbol = rule.symbol;
            price = market_data.price;
            quantity;
            side = `Buy;
            timestamp = Time.now ();
          } in
          if Risk.validate_order strategy.risk_params order then
            ignore (Bindings.Engine.submit engine order)
      | Sell quantity ->
          let order = {
            symbol = rule.symbol;
            price = market_data.price;
            quantity;
            side = `Sell;
            timestamp = Time.now ();
          } in
          if Risk.validate_order strategy.risk_params order then
            ignore (Bindings.Engine.submit engine order)
      | Cancel_all ->
          (* TODO: Implement cancel all orders for symbol *)
          ()
  in
  
  let process_market_data market_data =
    List.iter strategy.rules ~f:(fun rule -> execute_rule rule market_data)
  in
  
  market_data_stream.subscribe (function
    | Next market_data -> process_market_data market_data
    | Error exn -> printf "Strategy error: %s\n" (Exn.to_string exn)
    | Complete -> printf "Market data stream completed\n"
  )

(* Example strategy creation helper *)
let make_simple_strategy ~name ~symbol ~entry_price ~exit_price ~quantity ~risk_params =
  {
    name;
    rules = [
      { symbol;
        condition = Price_below entry_price;
        action = Buy quantity;
      };
      { symbol;
        condition = Price_above exit_price;
        action = Sell quantity;
      };
    ];
    risk_params;
  }

(* Example usage:
let strategy = make_simple_strategy
  ~name:"Simple Momentum"
  ~symbol:"AAPL"
  ~entry_price:150.0
  ~exit_price:155.0
  ~quantity:100
  ~risk_params:(Risk.create
    ~max_position_size:1000
    ~max_loss_per_trade:500.0
    ~max_daily_loss:5000.0)
*)
