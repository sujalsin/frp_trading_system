open Core
open Async

(* Event stream type *)
type 'a event = 
  | Next of 'a
  | Error of exn
  | Complete

(* Stream type representing a time-varying value *)
type 'a stream = {
  subscribe : ('a event -> unit) -> unit;
  unsubscribe : unit -> unit;
}

(* Create a new stream *)
let create_stream () =
  let subscribers = ref [] in
  let next value = 
    List.iter !subscribers ~f:(fun subscriber -> subscriber (Next value))
  in
  let error exn =
    List.iter !subscribers ~f:(fun subscriber -> subscriber (Error exn))
  in
  let complete () =
    List.iter !subscribers ~f:(fun subscriber -> subscriber Complete)
  in
  {
    subscribe = (fun callback -> subscribers := callback :: !subscribers);
    unsubscribe = (fun () -> subscribers := []);
  }

(* Basic operators *)
let map stream ~f =
  let new_stream = create_stream () in
  stream.subscribe (function
    | Next value -> new_stream.subscribe (fun cb -> cb (Next (f value)))
    | Error exn -> new_stream.subscribe (fun cb -> cb (Error exn))
    | Complete -> new_stream.subscribe (fun cb -> cb Complete)
  );
  new_stream

let filter stream ~f =
  let new_stream = create_stream () in
  stream.subscribe (function
    | Next value when f value -> 
        new_stream.subscribe (fun cb -> cb (Next value))
    | Error exn -> 
        new_stream.subscribe (fun cb -> cb (Error exn))
    | Complete -> 
        new_stream.subscribe (fun cb -> cb Complete)
    | _ -> ()
  );
  new_stream

(* Advanced stream operators *)
let merge streams =
  let new_stream = create_stream () in
  List.iter streams ~f:(fun stream ->
    stream.subscribe (fun event ->
      new_stream.subscribe (fun cb -> cb event))
  );
  new_stream

let debounce stream ~interval =
  let new_stream = create_stream () in
  let last_emit = ref (Time.now ()) in
  stream.subscribe (function
    | Next value ->
        let now = Time.now () in
        if Time.diff now !last_emit > interval then begin
          last_emit := now;
          new_stream.subscribe (fun cb -> cb (Next value))
        end
    | Error exn -> new_stream.subscribe (fun cb -> cb (Error exn))
    | Complete -> new_stream.subscribe (fun cb -> cb Complete)
  );
  new_stream

let sample stream ~interval =
  let new_stream = create_stream () in
  let running = ref true in
  let rec sample_loop () =
    if !running then begin
      upon (after interval) (fun () ->
        stream.subscribe (fun event ->
          match event with
          | Next value -> new_stream.subscribe (fun cb -> cb (Next value))
          | _ -> ());
        sample_loop ())
    end
  in
  sample_loop ();
  { new_stream with
    unsubscribe = (fun () ->
      running := false;
      new_stream.unsubscribe ())
  }

(* Market data types *)
type order = {
  symbol: string;
  price: float;
  quantity: int;
  side: [`Buy | `Sell];
  timestamp: Time.t;
}

type trade = {
  symbol: string;
  price: float;
  quantity: int;
  timestamp: Time.t;
  trade_id: string option;
}

type market_data = {
  symbol: string;
  bid: float;
  ask: float;
  last_price: float;
  volume: int;
  timestamp: Time.t;
}

(* Market data streams *)
let create_market_data_stream symbol =
  let stream = create_stream () in
  let running = ref true in
  
  (* Simulated market data generator for testing *)
  let rec generate_data () =
    if !running then begin
      let data = {
        symbol;
        bid = Random.float 100.0;
        ask = Random.float 100.0 +. 0.1;
        last_price = Random.float 100.0;
        volume = Random.int 1000;
        timestamp = Time.now ();
      } in
      stream.subscribe (fun cb -> cb (Next data));
      upon (after (Time.Span.of_sec 1.0)) generate_data
    end
  in
  
  generate_data ();
  
  { stream with
    unsubscribe = (fun () ->
      running := false;
      stream.unsubscribe ())
  }

(* Trading strategy type *)
type strategy = {
  name: string;
  entry_conditions: market_data stream -> bool;
  exit_conditions: market_data stream -> bool;
  position_size: float -> int;  (* Calculate position size based on account equity *)
  max_positions: int;
}

(* Risk management module *)
module Risk = struct
  type t = {
    max_position_size: int;
    max_loss_per_trade: float;
    max_daily_loss: float;
    max_positions_per_symbol: int;
    position_sizing_factor: float;  (* As percentage of account equity *)
  }

  let create ~max_position_size ~max_loss_per_trade ~max_daily_loss
             ~max_positions_per_symbol ~position_sizing_factor =
    { max_position_size;
      max_loss_per_trade;
      max_daily_loss;
      max_positions_per_symbol;
      position_sizing_factor;
    }

  let validate_order risk order =
    order.quantity <= risk.max_position_size

  let calculate_position_size risk equity price =
    let max_notional = equity *. risk.position_sizing_factor in
    let quantity = Float.to_int (max_notional /. price) in
    Int.min quantity risk.max_position_size
end

(* Position tracking *)
module Position = struct
  type t = {
    symbol: string;
    quantity: int;
    avg_price: float;
    unrealized_pnl: float;
    realized_pnl: float;
  }

  let create symbol ~quantity ~price = {
    symbol;
    quantity;
    avg_price = price;
    unrealized_pnl = 0.0;
    realized_pnl = 0.0;
  }

  let update_pnl pos ~current_price =
    let unrealized = Float.of_int pos.quantity *. (current_price -. pos.avg_price) in
    { pos with unrealized_pnl = unrealized }

  let add_trade pos ~quantity ~price =
    let total_quantity = pos.quantity + quantity in
    let avg_price =
      if total_quantity = 0 then pos.avg_price
      else (pos.avg_price *. Float.of_int pos.quantity +.
            price *. Float.of_int quantity) /.
           Float.of_int total_quantity
    in
    { pos with
      quantity = total_quantity;
      avg_price = avg_price;
    }
end
