(* Todo Application using Virtual DOM *)
(* This file demonstrates a complete todo application using our virtual DOM *)

open Virtual_dom

(* Todo item type *)
type todo_item = {
  id: int;
  text: string;
  completed: bool;
}

(* Todo application state *)
type todo_state = {
  todos: todo_item list;
  new_todo_text: string;
  filter: string;
}

(* Todo component *)
let todo_component =
  let render props state =
    let filtered_todos = 
      match state.filter with
      | "active" -> List.filter (fun t -> not t.completed) state.todos
      | "completed" -> List.filter (fun t -> t.completed) state.todos
      | _ -> state.todos
    in
    
    div [("class", "todo-app")]
      [
        h1 [] [create_text "Todo App"];
        
        (* Add todo form *)
        form [("onsubmit", "add_todo")]
          [
            input 
              [("type", "text"); ("value", state.new_todo_text); ("placeholder", "Add a todo")]
              [];
            button [("type", "submit")] [create_text "Add"]
          ];
        
        (* Filter buttons *)
        div [("class", "filters")]
          [
            button [("onclick", "filter_all")] [create_text "All"];
            button [("onclick", "filter_active")] [create_text "Active"];
            button [("onclick", "filter_completed")] [create_text "Completed"];
          ];
        
        (* Todo list *)
        ul [("class", "todo-list")]
          (List.mapi (fun i todo ->
            li 
              [("class", if todo.completed then "completed" else "active");
               ("key", string_of_int todo.id)]
              [
                input 
                  [("type", "checkbox"); 
                   ("checked", string_of_bool todo.completed);
                   ("onchange", "toggle_todo");
                   ("data-id", string_of_int todo.id)]
                  [];
                span [] [create_text todo.text];
                button 
                  [("onclick", "delete_todo"); 
                   ("data-id", string_of_int todo.id)]
                  [create_text "Delete"]
              ]
          ) filtered_todos)
      ]
  in
  
  let update props state =
    (* Handle different actions based on props *)
    match List.assoc_opt "action" props with
    | Some "add_todo" ->
        let new_todo = {
          id = (match state.todos with [] -> 1 | _ -> 
                List.fold_left (fun max t -> max t.id) 0 state.todos + 1);
          text = state.new_todo_text;
          completed = false;
        } in
        { state with 
          todos = new_todo :: state.todos;
          new_todo_text = ""
        }
    | Some "toggle_todo" ->
        let todo_id = int_of_string (List.assoc "todo_id" props) in
        let updated_todos = 
          List.map (fun todo ->
            if todo.id = todo_id then
              { todo with completed = not todo.completed }
            else
              todo
          ) state.todos
        in
        { state with todos = updated_todos }
    | Some "delete_todo" ->
        let todo_id = int_of_string (List.assoc "todo_id" props) in
        let filtered_todos = 
          List.filter (fun todo -> todo.id <> todo_id) state.todos
        in
        { state with todos = filtered_todos }
    | Some "set_filter" ->
        { state with filter = List.assoc "filter" props }
    | Some "update_text" ->
        { state with new_todo_text = List.assoc "text" props }
    | _ -> state
  in
  
  create_component "TodoApp" render update

(* Initial state *)
let initial_state = {
  todos = [];
  new_todo_text = "";
  filter = "all";
}

(* Example usage *)
let example_todos = [
  { id = 1; text = "Learn OCaml"; completed = false };
  { id = 2; text = "Build Virtual DOM"; completed = true };
  { id = 3; text = "Write blog post"; completed = false };
]

let state_with_todos = { initial_state with todos = example_todos }

(* Render the todo app *)
let todo_app_vdom = todo_component.render [] 
  { data = [("todos", example_todos); ("filter", "all"); ("new_todo_text", "")] }

(* Print the todo app *)
let () =
  print_endline "Todo Application Virtual DOM:";
  print_vdom 0 todo_app_vdom