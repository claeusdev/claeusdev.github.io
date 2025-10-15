(* Performance Testing for Virtual DOM *)
(* This file contains benchmarks and performance tests *)

open Virtual_dom

(* Generate a large virtual DOM tree for testing *)
let rec generate_large_tree depth width =
  if depth <= 0 then
    create_text ("Leaf " ^ string_of_int (Random.int 1000))
  else
    let children = 
      List.init width (fun _ -> generate_large_tree (depth - 1) width)
    in
    div [("class", "node"); ("depth", string_of_int depth)] children

(* Benchmark diff operations *)
let benchmark_diff old_tree new_tree iterations =
  let start_time = Sys.time () in
  let rec run_benchmark i =
    if i <= 0 then ()
    else begin
      ignore (diff old_tree new_tree 0);
      run_benchmark (i - 1)
    end
  in
  run_benchmark iterations;
  let end_time = Sys.time () in
  end_time -. start_time

(* Memory usage estimation *)
let estimate_memory_usage vdom =
  let rec count_nodes = function
    | Text _ -> 1
    | Element { children; _ } -> 
        1 + List.fold_left (fun acc child -> acc + count_nodes child) 0 children
  in
  let node_count = count_nodes vdom in
  (* Rough estimation: each node takes ~100 bytes *)
  node_count * 100

(* Performance comparison with different tree sizes *)
let performance_comparison () =
  let sizes = [10; 50; 100; 500; 1000] in
  let iterations = 100 in
  
  print_endline "Virtual DOM Performance Test";
  print_endline "=============================";
  print_endline "Tree Size | Diff Time (ms) | Memory (KB)";
  print_endline "----------|----------------|------------";
  
  List.iter (fun size ->
    let tree1 = generate_large_tree 3 size in
    let tree2 = generate_large_tree 3 size in
    let diff_time = benchmark_diff tree1 tree2 iterations in
    let memory = estimate_memory_usage tree1 in
    Printf.printf "%8d | %13.2f | %10d\n" 
      size (diff_time *. 1000.0) (memory / 1024)
  ) sizes

(* Stress test with many operations *)
let stress_test () =
  print_endline "\nStress Test: 1000 diff operations";
  print_endline "==================================";
  
  let tree1 = generate_large_tree 2 10 in
  let tree2 = generate_large_tree 2 10 in
  
  let start_time = Sys.time () in
  for i = 1 to 1000 do
    ignore (diff tree1 tree2 0)
  done;
  let end_time = Sys.time () in
  
  Printf.printf "Time for 1000 diffs: %.2f ms\n" ((end_time -. start_time) *. 1000.0)

(* Component rendering performance *)
let component_performance_test () =
  print_endline "\nComponent Rendering Performance";
  print_endline "===============================";
  
  let component = todo_component in
  let state = { data = [("todos", []); ("filter", "all"); ("new_todo_text", "")] } in
  
  let start_time = Sys.time () in
  for i = 1 to 1000 do
    ignore (component.render [] state)
  done;
  let end_time = Sys.time () in
  
  Printf.printf "Time for 1000 component renders: %.2f ms\n" 
    ((end_time -. start_time) *. 1000.0)

(* Run all performance tests *)
let () =
  Random.self_init ();
  performance_comparison ();
  stress_test ();
  component_performance_test ()