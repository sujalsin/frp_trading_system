open Core
open OUnit2

let test_market_data_subscription _test_ctxt =
  let engine = ExecutionEngine.create () in
  let received_data = ref None in
  let symbol = "AAPL" in

  ExecutionEngine.start engine;
  ExecutionEngine.subscribe_market_data engine symbol (fun data ->
    received_data := Some data
  );

  (* Wait a bit to receive market data *)
  Unix.sleep 1;

  match !received_data with
  | None -> assert_failure "No market data received"
  | Some data ->
    assert_equal data.symbol symbol;
    assert (data.bid > 0.0);
    assert (data.ask > data.bid);
    assert (data.volume > 0L);

  ExecutionEngine.stop engine;
  ExecutionEngine.destroy engine

let test_order_submission _test_ctxt =
  let engine = ExecutionEngine.create () in
  let symbol = "AAPL" in
  let order = {
    symbol;
    price = 150.0;
    quantity = 100;
    side = Buy;
    order_id = None;
  } in

  ExecutionEngine.start engine;
  let order_with_id = ExecutionEngine.submit_order engine order in
  assert (Option.is_some order_with_id.order_id);

  (* Wait for order processing *)
  Unix.sleep 1;

  let position = ExecutionEngine.get_position engine symbol in
  assert (position = 100);

  let avg_price = ExecutionEngine.get_average_price engine symbol in
  assert (avg_price > 0.0);

  ExecutionEngine.stop engine;
  ExecutionEngine.destroy engine

let test_trade_notification _test_ctxt =
  let engine = ExecutionEngine.create () in
  let received_trade = ref None in
  let symbol = "AAPL" in

  ExecutionEngine.start engine;
  ExecutionEngine.subscribe_trades engine symbol (fun trade ->
    received_trade := Some trade
  );

  (* Submit matching orders *)
  let buy_order = {
    symbol;
    price = 150.0;
    quantity = 100;
    side = Buy;
    order_id = None;
  } in
  let sell_order = {
    symbol;
    price = 150.0;
    quantity = 100;
    side = Sell;
    order_id = None;
  } in

  ignore (ExecutionEngine.submit_order engine buy_order);
  ignore (ExecutionEngine.submit_order engine sell_order);

  (* Wait for trade processing *)
  Unix.sleep 1;

  match !received_trade with
  | None -> assert_failure "No trade received"
  | Some trade ->
    assert_equal trade.symbol symbol;
    assert_equal trade.quantity 100;
    assert (trade.price >= 150.0);

  ExecutionEngine.stop engine;
  ExecutionEngine.destroy engine

let test_pnl_calculation _test_ctxt =
  let engine = ExecutionEngine.create () in
  let symbol = "AAPL" in

  ExecutionEngine.start engine;

  (* Submit a buy order *)
  let buy_order = {
    symbol;
    price = 150.0;
    quantity = 100;
    side = Buy;
    order_id = None;
  } in
  ignore (ExecutionEngine.submit_order engine buy_order);

  (* Wait for order processing *)
  Unix.sleep 1;

  let unrealized_pnl = ExecutionEngine.get_unrealized_pnl engine symbol in
  let realized_pnl = ExecutionEngine.get_realized_pnl engine symbol in

  assert (unrealized_pnl <> 0.0);  (* Should have some P&L due to market moves *)
  assert_equal realized_pnl 0.0;   (* No realized P&L yet *)

  (* Submit a sell order to realize P&L *)
  let sell_order = {
    symbol;
    price = 151.0;
    quantity = 100;
    side = Sell;
    order_id = None;
  } in
  ignore (ExecutionEngine.submit_order engine sell_order);

  (* Wait for order processing *)
  Unix.sleep 1;

  let final_realized_pnl = ExecutionEngine.get_realized_pnl engine symbol in
  assert (final_realized_pnl > 0.0);  (* Should have realized profit *)

  ExecutionEngine.stop engine;
  ExecutionEngine.destroy engine

let suite =
  "execution_engine_test" >::: [
    "test_market_data_subscription" >:: test_market_data_subscription;
    "test_order_submission" >:: test_order_submission;
    "test_trade_notification" >:: test_trade_notification;
    "test_pnl_calculation" >:: test_pnl_calculation;
  ]

let () =
  run_test_tt_main suite
