(* DOM Renderer for Virtual DOM *)
(* This file contains the browser DOM integration *)

open Virtual_dom
open Js_of_ocaml

(* Convert virtual DOM to real DOM *)
let rec render_to_dom = function
  | Text text ->
      let text_node = Dom_html.document##createTextNode (Js.string text) in
      text_node
  
  | Element { tag; props; children } ->
      let element = Dom_html.document##createElement (Js.string tag) in
      
      (* Set properties *)
      List.iter (fun (key, value) ->
        element##setAttribute (Js.string key) (Js.string value)
      ) props;
      
      (* Render children *)
      List.iter (fun child ->
        let child_dom = render_to_dom child in
        ignore (element##appendChild child_dom)
      ) children;
      
      element

(* Apply diff operations to DOM *)
let apply_diff_operations operations root_element =
  let rec apply_at_path element path remaining_ops =
    match remaining_ops with
    | [] -> ()
    | (op_path, op) :: rest ->
        if op_path = path then
          match op with
          | Create vdom ->
              let new_dom = render_to_dom vdom in
              ignore (element##appendChild new_dom)
          | Update vdom ->
              let new_dom = render_to_dom vdom in
              let old_child = element##childNodes##item path in
              ignore (element##replaceChild new_dom old_child)
          | Remove ->
              let child = element##childNodes##item path in
              ignore (element##removeChild child)
          | Replace vdom ->
              let new_dom = render_to_dom vdom in
              let old_child = element##childNodes##item path in
              ignore (element##replaceChild new_dom old_child)
        else
          apply_at_path element (path + 1) remaining_ops
  in
  
  apply_at_path root_element 0 operations

(* Event handler system *)
let event_handlers = Hashtbl.create 16

let register_event_handler event_name handler =
  Hashtbl.add event_handlers event_name handler

let handle_event event_name data =
  try
    let handler = Hashtbl.find event_handlers event_name in
    handler data
  with Not_found ->
    Printf.printf "No handler for event: %s\n" event_name

(* Initialize event listeners *)
let init_event_listeners () =
  (* Add click handlers *)
  register_event_handler "handleClick" (fun _ ->
    print_endline "Button clicked!"
  );
  
  (* Add form submission handlers *)
  register_event_handler "add_todo" (fun _ ->
    print_endline "Adding todo..."
  );
  
  (* Add filter handlers *)
  register_event_handler "filter_all" (fun _ ->
    print_endline "Filtering: All"
  );
  
  register_event_handler "filter_active" (fun _ ->
    print_endline "Filtering: Active"
  );
  
  register_event_handler "filter_completed" (fun _ ->
    print_endline "Filtering: Completed"
  )

(* Main application setup *)
let setup_app () =
  init_event_listeners ();
  
  (* Create a simple example *)
  let example_vdom = 
    div [("class", "app")]
      [
        h1 [] [create_text "Virtual DOM in OCaml"];
        p [] [create_text "This is rendered using our virtual DOM system."];
        button [("onclick", "handleClick")] [create_text "Click me!"];
        div [("id", "todo-container")] []
      ]
  in
  
  (* Render to DOM *)
  let root_element = Dom_html.getElementById "app" in
  let rendered_dom = render_to_dom example_vdom in
  ignore (root_element##appendChild rendered_dom)

(* Initialize when DOM is ready *)
let () =
  Dom_html.window##.onload := Dom_html.handler (fun _ ->
    setup_app ();
    Js._false
  )