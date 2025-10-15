(* Virtual DOM Implementation in OCaml *)
(* This file contains the core virtual DOM data structures and algorithms *)

(* Virtual DOM element types *)
type vdom =
  | Text of string
  | Element of {
      tag: string;
      props: (string * string) list;
      children: vdom list;
    }

(* DOM operations for patching *)
type dom_op =
  | Create of vdom
  | Update of vdom
  | Remove
  | Replace of vdom

(* Diff result for efficient updates *)
type diff_result = {
  operations: (int * dom_op) list;
  new_tree: vdom;
}

(* Component state and props *)
type component_state = {
  mutable data: (string * 'a) list;
}

type component_props = (string * 'a) list

(* Component definition *)
type component = {
  name: string;
  render: component_props -> component_state -> vdom;
  update: component_props -> component_state -> component_state;
}

(* Create a virtual element *)
let create_element tag props children =
  Element { tag; props; children }

(* Create text node *)
let create_text text = Text text

(* Helper to get element properties *)
let get_props = function
  | Element { props; _ } -> props
  | Text _ -> []

(* Helper to get children *)
let get_children = function
  | Element { children; _ } -> children
  | Text _ -> []

(* Check if two vdom nodes are the same type *)
let same_type v1 v2 =
  match v1, v2 with
  | Text _, Text _ -> true
  | Element { tag = t1; _ }, Element { tag = t2; _ } -> t1 = t2
  | _ -> false

(* Diff two virtual DOM trees *)
let rec diff old_tree new_tree path =
  match old_tree, new_tree with
  | Text old_text, Text new_text ->
      if old_text = new_text then
        { operations = []; new_tree = new_tree }
      else
        { operations = [(path, Replace new_tree)]; new_tree = new_tree }
  
  | Element old_elem, Element new_elem ->
      if old_elem.tag <> new_elem.tag then
        { operations = [(path, Replace new_tree)]; new_tree = new_tree }
      else
        diff_element old_elem new_elem path
  
  | _, _ ->
      { operations = [(path, Replace new_tree)]; new_tree = new_tree }

and diff_element old_elem new_elem path =
  let props_changed = old_elem.props <> new_elem.props in
  let children_diff = diff_children old_elem.children new_elem.children (path + 1) in
  
  let operations = 
    if props_changed then
      (path, Update (Element new_elem)) :: children_diff.operations
    else
      children_diff.operations
  in
  
  { operations; new_tree = Element new_elem }

and diff_children old_children new_children start_path =
  let rec diff_children_rec old_list new_list path acc =
    match old_list, new_list with
    | [], [] -> { operations = List.rev acc; new_tree = Text "" }
    | old_hd :: old_tl, new_hd :: new_tl ->
        let child_diff = diff old_hd new_hd path in
        let new_acc = List.rev_append child_diff.operations acc in
        diff_children_rec old_tl new_tl (path + 1) new_acc
    | old_hd :: old_tl, [] ->
        let new_acc = (path, Remove) :: acc in
        diff_children_rec old_tl [] (path + 1) new_acc
    | [], new_hd :: new_tl ->
        let new_acc = (path, Create new_hd) :: acc in
        diff_children_rec [] new_tl (path + 1) new_acc
  in
  
  diff_children_rec old_children new_children start_path []

(* Create a component *)
let create_component name render update =
  { name; render; update }

(* Memoized component rendering *)
let memoize_component component =
  let cache = Hashtbl.create 16 in
  {
    component with
    render = (fun props state ->
      let key = (props, state.data) in
      try Hashtbl.find cache key
      with Not_found ->
        let result = component.render props state in
        Hashtbl.add cache key result;
        result
    )
  }

(* Key-based list reconciliation *)
let diff_keyed_children old_children new_children =
  let old_map = 
    List.mapi (fun i child -> (i, child)) old_children
    |> List.to_seq |> Hashtbl.of_seq
  in
  
  let rec process_new_children new_list acc =
    match new_list with
    | [] -> List.rev acc
    | new_child :: rest ->
        (* Find matching old child by key or position *)
        let operation = 
          if Hashtbl.mem old_map (List.length acc) then
            let old_child = Hashtbl.find old_map (List.length acc) in
            if same_type old_child new_child then
              Update new_child
            else
              Replace new_child
          else
            Create new_child
        in
        process_new_children rest ((List.length acc, operation) :: acc)
  in
  
  process_new_children new_children []

(* Utility functions for building virtual DOM *)
let div props children = create_element "div" props children
let span props children = create_element "span" props children
let h1 props children = create_element "h1" props children
let h2 props children = create_element "h2" props children
let p props children = create_element "p" props children
let button props children = create_element "button" props children
let input props children = create_element "input" props children
let ul props children = create_element "ul" props children
let li props children = create_element "li" props children
let form props children = create_element "form" props children

(* Example usage and testing *)
let example_vdom =
  div [("class", "container")]
    [
      h1 [] [create_text "Hello, Virtual DOM!"];
      p [("id", "description")] 
        [create_text "This is a virtual DOM tree in OCaml."];
      button [("onclick", "handleClick")] 
        [create_text "Click me!"]
    ]

(* Print virtual DOM tree for debugging *)
let rec print_vdom indent = function
  | Text text ->
      Printf.printf "%sText: %s\n" (String.make indent ' ') text
  | Element { tag; props; children } ->
      Printf.printf "%sElement: %s\n" (String.make indent ' ') tag;
      List.iter (fun (key, value) ->
        Printf.printf "%s  %s: %s\n" (String.make (indent + 2) ' ') key value
      ) props;
      List.iter (print_vdom (indent + 2)) children

(* Test the virtual DOM *)
let () =
  print_endline "Virtual DOM Example:";
  print_vdom 0 example_vdom;
  print_endline "\nDiff test:";
  let old_tree = div [] [create_text "Hello"];
  let new_tree = div [] [create_text "World"];
  let diff_result = diff old_tree new_tree 0 in
  Printf.printf "Operations: %d\n" (List.length diff_result.operations)