open Core
open Ctypes
open Foreign
open PosixTypes

(* Types *)
type order_side = Buy | Sell
let order_side = enum "order_side" [
  Buy, 0;
  Sell, 1;
]

type order = {
  symbol: string;
  price: float;
  quantity: int;
  side: order_side;
  order_id: string option;
}

type trade = {
  symbol: string;
  price: float;
  quantity: int;
  timestamp: float;
  buyer_order_id: string;
  seller_order_id: string;
}

type market_data = {
  symbol: string;
  bid: float;
  ask: float;
  last: float;
  volume: int64;
  timestamp: float;
}

(* C++ class wrapper *)
type execution_engine
let execution_engine : execution_engine structure typ = structure "ExecutionEngine"

(* Function bindings *)
let create_execution_engine = 
  foreign "new_execution_engine" (void @-> returning (ptr execution_engine))

let destroy_execution_engine =
  foreign "delete_execution_engine" (ptr execution_engine @-> returning void)

let start_engine =
  foreign "start_engine" (ptr execution_engine @-> returning void)

let stop_engine =
  foreign "stop_engine" (ptr execution_engine @-> returning void)

let submit_order =
  foreign "submit_order" (
    ptr execution_engine @->
    string @-> (* symbol *)
    double @-> (* price *)
    int @-> (* quantity *)
    order_side @-> (* side *)
    returning string
  )

let cancel_order =
  foreign "cancel_order" (
    ptr execution_engine @->
    string @-> (* order_id *)
    returning bool
  )

let get_position =
  foreign "get_position" (
    ptr execution_engine @->
    string @-> (* symbol *)
    returning int
  )

let get_average_price =
  foreign "get_average_price" (
    ptr execution_engine @->
    string @-> (* symbol *)
    returning double
  )

let get_unrealized_pnl =
  foreign "get_unrealized_pnl" (
    ptr execution_engine @->
    string @-> (* symbol *)
    returning double
  )

let get_realized_pnl =
  foreign "get_realized_pnl" (
    ptr execution_engine @->
    string @-> (* symbol *)
    returning double
  )

(* Callback types *)
type market_data_callback = market_data -> unit
type trade_callback = trade -> unit

let market_data_callback_typ = 
  Foreign.funptr (
    ptr void @-> (* market data struct *)
    returning void
  )

let trade_callback_typ =
  Foreign.funptr (
    ptr void @-> (* trade struct *)
    returning void
  )

let subscribe_market_data =
  foreign "subscribe_market_data" (
    ptr execution_engine @->
    string @-> (* symbol *)
    market_data_callback_typ @->
    returning void
  )

let unsubscribe_market_data =
  foreign "unsubscribe_market_data" (
    ptr execution_engine @->
    string @-> (* symbol *)
    returning void
  )

let subscribe_trades =
  foreign "subscribe_trades" (
    ptr execution_engine @->
    string @-> (* symbol *)
    trade_callback_typ @->
    returning void
  )

let unsubscribe_trades =
  foreign "unsubscribe_trades" (
    ptr execution_engine @->
    string @-> (* symbol *)
    returning void
  )

(* High-level wrapper *)
module ExecutionEngine = struct
  type t = {
    engine: execution_engine ptr;
    mutable market_data_callbacks: (string, market_data_callback list) Hashtbl.t;
    mutable trade_callbacks: (string, trade_callback list) Hashtbl.t;
  }

  let create () =
    let engine = create_execution_engine () in
    {
      engine;
      market_data_callbacks = Hashtbl.create (module String);
      trade_callbacks = Hashtbl.create (module String);
    }

  let destroy t =
    destroy_execution_engine t.engine

  let start t =
    start_engine t.engine

  let stop t =
    stop_engine t.engine

  let submit_order t order =
    let order_id = submit_order 
      t.engine 
      order.symbol 
      order.price 
      order.quantity 
      order.side
    in
    { order with order_id = Some order_id }

  let cancel_order t order_id =
    cancel_order t.engine order_id

  let get_position t symbol =
    get_position t.engine symbol

  let get_average_price t symbol =
    get_average_price t.engine symbol

  let get_unrealized_pnl t symbol =
    get_unrealized_pnl t.engine symbol

  let get_realized_pnl t symbol =
    get_realized_pnl t.engine symbol

  let subscribe_market_data t symbol callback =
    let callbacks = 
      match Hashtbl.find t.market_data_callbacks symbol with
      | Some cbs -> callback :: cbs
      | None -> [callback]
    in
    Hashtbl.set t.market_data_callbacks ~key:symbol ~data:callbacks;
    subscribe_market_data t.engine symbol (fun data ->
      List.iter callbacks ~f:(fun cb -> cb data)
    )

  let unsubscribe_market_data t symbol =
    Hashtbl.remove t.market_data_callbacks symbol;
    unsubscribe_market_data t.engine symbol

  let subscribe_trades t symbol callback =
    let callbacks = 
      match Hashtbl.find t.trade_callbacks symbol with
      | Some cbs -> callback :: cbs
      | None -> [callback]
    in
    Hashtbl.set t.trade_callbacks ~key:symbol ~data:callbacks;
    subscribe_trades t.engine symbol (fun trade ->
      List.iter callbacks ~f:(fun cb -> cb trade)
    )

  let unsubscribe_trades t symbol =
    Hashtbl.remove t.trade_callbacks symbol;
    unsubscribe_trades t.engine symbol
end
