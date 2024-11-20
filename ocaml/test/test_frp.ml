open Core
open Async
open Frp_trading
open Frp

let%test_unit "test_stream_operators" =
  let stream = create_stream () in
  let doubled = map stream ~f:(fun x -> x * 2) in
  let filtered = filter doubled ~f:(fun x -> x > 10) in
  
  let received = ref [] in
  filtered.subscribe (function
    | Next value -> received := value :: !received
    | _ -> ()
  );
  
  stream.subscribe (fun cb -> cb (Next 3));
  stream.subscribe (fun cb -> cb (Next 6));
  stream.subscribe (fun cb -> cb (Next 8));
  
  [%test_result: int list] !received ~expect:[16; 12]

let%test_unit "test_market_data_stream" =
  let stream = create_market_data_stream "AAPL" in
  let received = ref 0 in
  
  stream.subscribe (function
    | Next data ->
        received := !received + 1;
        [%test_pred: float] Float.is_positive data.bid;
        [%test_pred: float] Float.is_positive data.ask;
        [%test_pred: float] Float.is_positive data.last_price;
        [%test_pred: int] Int.is_positive data.volume;
        [%test_result: string] data.symbol ~expect:"AAPL"
    | _ -> ()
  );
  
  after (Time.Span.of_sec 2.0) >>| fun () ->
  [%test_pred: int] (fun x -> x >= 1) !received

let%test_unit "test_risk_management" =
  let risk_params = Risk.create
    ~max_position_size:1000
    ~max_loss_per_trade:500.0
    ~max_daily_loss:5000.0
    ~max_positions_per_symbol:2
    ~position_sizing_factor:0.02
  in
  
  let valid_order = {
    symbol = "AAPL";
    price = 150.0;
    quantity = 500;
    side = `Buy;
    timestamp = Time.now ();
  } in
  
  let invalid_order = {
    symbol = "AAPL";
    price = 150.0;
    quantity = 1500;  (* Exceeds max_position_size *)
    side = `Buy;
    timestamp = Time.now ();
  } in
  
  [%test_result: bool] (Risk.validate_order risk_params valid_order) ~expect:true;
  [%test_result: bool] (Risk.validate_order risk_params invalid_order) ~expect:false

let%test_unit "test_position_tracking" =
  let pos = Position.create "AAPL" ~quantity:100 ~price:150.0 in
  
  (* Test initial position *)
  [%test_result: string] pos.symbol ~expect:"AAPL";
  [%test_result: int] pos.quantity ~expect:100;
  [%test_result: float] pos.avg_price ~expect:150.0;
  [%test_result: float] pos.unrealized_pnl ~expect:0.0;
  
  (* Test adding a trade *)
  let pos = Position.add_trade pos ~quantity:50 ~price:160.0 in
  [%test_result: int] pos.quantity ~expect:150;
  [%test_result: float] pos.avg_price ~expect:153.33333333333334;
  
  (* Test PnL calculation *)
  let pos = Position.update_pnl pos ~current_price:165.0 in
  [%test_result: float] pos.unrealized_pnl ~expect:1750.0  (* (165 - 153.33) * 150 *)

let%test_unit "test_stream_merge" =
  let stream1 = create_stream () in
  let stream2 = create_stream () in
  let merged = merge [stream1; stream2] in
  
  let received = ref [] in
  merged.subscribe (function
    | Next value -> received := value :: !received
    | _ -> ()
  );
  
  stream1.subscribe (fun cb -> cb (Next 1));
  stream2.subscribe (fun cb -> cb (Next 2));
  stream1.subscribe (fun cb -> cb (Next 3));
  
  [%test_result: int list] !received ~expect:[3; 2; 1]

let%test_unit "test_stream_debounce" =
  let stream = create_stream () in
  let debounced = debounce stream ~interval:(Time.Span.of_sec 0.1) in
  
  let received = ref [] in
  debounced.subscribe (function
    | Next value -> received := value :: !received
    | _ -> ()
  );
  
  stream.subscribe (fun cb -> cb (Next 1));
  after (Time.Span.of_sec 0.05) >>= fun () ->
  stream.subscribe (fun cb -> cb (Next 2));  (* Should be ignored *)
  after (Time.Span.of_sec 0.15) >>= fun () ->
  stream.subscribe (fun cb -> cb (Next 3));
  after (Time.Span.of_sec 0.2) >>| fun () ->
  [%test_result: int list] !received ~expect:[3; 1]
