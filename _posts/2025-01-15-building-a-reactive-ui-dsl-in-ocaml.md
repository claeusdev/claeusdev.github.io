---
layout: post
title: "Building a Reactive UI DSL in OCaml: A Simple React-like Framework"
date: 2025-01-15 10:00:00 -0000
categories: [ocaml, functional-programming, ui, dsl]
tags: [ocaml, reactive-programming, ui-framework, functional-programming]
excerpt: "Learn how to build a simple reactive DSL for UI applications in OCaml, inspired by React's component model and virtual DOM."
---

# Building a Reactive UI DSL in OCaml: A Simple React-like Framework

In this tutorial, we'll build a simple reactive DSL for UI applications in OCaml, inspired by React's component model and virtual DOM. Our framework will demonstrate key concepts like:

- Virtual DOM representation
- Component state management
- Event handling
- Reactive updates
- Functional composition

## Table of Contents

1. [Introduction](#introduction)
2. [Core Types and Virtual DOM](#core-types-and-virtual-dom)
3. [State Management](#state-management)
4. [Component System](#component-system)
5. [Event Handling](#event-handling)
6. [Rendering Engine](#rendering-engine)
7. [Putting It All Together](#putting-it-all-together)
8. [Advanced Features](#advanced-features)
9. [Conclusion](#conclusion)

## Introduction

React revolutionized frontend development by introducing the virtual DOM and component-based architecture. We can apply similar principles in OCaml to create a functional, type-safe UI framework. Our DSL will be:

- **Functional**: Components are pure functions
- **Type-safe**: OCaml's type system prevents many runtime errors
- **Composable**: Small components combine to build complex UIs
- **Reactive**: State changes automatically trigger re-renders

## Core Types and Virtual DOM

Let's start by defining our core types for representing UI elements:

```ocaml
(* reactive_ui.ml *)

(* Basic types for our virtual DOM *)
type attribute = 
  | String of string * string
  | Bool of string * bool
  | Event of string * (unit -> unit)

type element = 
  | Text of string
  | Element of string * attribute list * element list
  | Component of (unit -> element)

(* State management *)
type 'a state = {
  value: 'a;
  set_value: 'a -> unit;
  subscribers: (unit -> unit) list;
}

(* Component context *)
type context = {
  state: (string, unit state) Hashtbl.t;
  counter: int ref;
}

let create_context () = {
  state = Hashtbl.create 10;
  counter = ref 0;
}
```

## State Management

Our state management system uses closures and a simple subscription model:

```ocaml
(* State management functions *)
let create_state (initial_value: 'a) : 'a state =
  let subscribers = ref [] in
  let value = ref initial_value in
  {
    value = !value;
    set_value = (fun new_value ->
      value := new_value;
      List.iter (fun callback -> callback ()) !subscribers
    );
    subscribers = !subscribers;
  }

let subscribe (state: 'a state) (callback: unit -> unit) : unit =
  state.subscribers <- callback :: state.subscribers

let get_value (state: 'a state) : 'a = state.value

let set_value (state: 'a state) (value: 'a) : unit = 
  state.set_value value
```

## Component System

Now let's build our component system with hooks:

```ocaml
(* Hook system for components *)
let use_state (initial_value: 'a) (ctx: context) : 'a state =
  let key = string_of_int !(ctx.counter) in
  ctx.counter := !(ctx.counter) + 1;
  
  if Hashtbl.mem ctx.state key then
    Hashtbl.find ctx.state key
  else
    let state = create_state initial_value in
    Hashtbl.add ctx.state key state;
    state

let use_effect (effect: unit -> unit) (deps: 'a list) (ctx: context) : unit =
  (* Simplified effect hook - in a real implementation, 
     you'd track dependencies and only run when they change *)
  effect ()

(* Component creation helpers *)
let create_element (tag: string) (attrs: attribute list) (children: element list) : element =
  Element (tag, attrs, children)

let create_text (text: string) : element =
  Text text

let create_component (component_fn: unit -> element) : element =
  Component component_fn
```

## Event Handling

Let's add event handling capabilities:

```ocaml
(* Event handling *)
let on_click (handler: unit -> unit) : attribute =
  Event ("onclick", handler)

let on_input (handler: string -> unit) : attribute =
  Event ("oninput", (fun () -> handler ""))

let on_change (handler: string -> unit) : attribute =
  Event ("onchange", (fun () -> handler ""))

(* Event dispatcher *)
let dispatch_event (event_name: string) (element: element) : unit =
  match element with
  | Element (_, attrs, _) ->
    List.iter (fun attr ->
      match attr with
      | Event (name, handler) when name = event_name -> handler ()
      | _ -> ()
    ) attrs
  | _ -> ()
```

## Rendering Engine

Our simple rendering engine converts virtual DOM to HTML:

```ocaml
(* Rendering engine *)
let rec render_element (element: element) : string =
  match element with
  | Text text -> text
  | Element (tag, attrs, children) ->
    let attrs_str = String.concat " " (List.map render_attribute attrs) in
    let children_str = String.concat "" (List.map render_element children) in
    Printf.sprintf "<%s %s>%s</%s>" tag attrs_str children_str tag
  | Component component_fn -> render_element (component_fn ())

and render_attribute (attr: attribute) : string =
  match attr with
  | String (name, value) -> Printf.sprintf "%s=\"%s\"" name value
  | Bool (name, true) -> name
  | Bool (name, false) -> ""
  | Event (name, _) -> "" (* Events are handled separately *)

(* Main render function *)
let render (element: element) : string =
  render_element element
```

## Putting It All Together

Let's create a complete example that demonstrates our reactive DSL:

```ocaml
(* Example application *)
let counter_component (ctx: context) : element =
  let count, set_count = use_state 0 ctx in
  let increment = fun () -> set_count (get_value count + 1) in
  let decrement = fun () -> set_count (get_value count - 1) in
  
  create_element "div" [] [
    create_element "h1" [] [create_text "Counter Example"];
    create_element "p" [] [create_text (Printf.sprintf "Count: %d" (get_value count))];
    create_element "button" [on_click increment] [create_text "Increment"];
    create_element "button" [on_click decrement] [create_text "Decrement"];
  ]

let todo_component (ctx: context) : element =
  let todos, set_todos = use_state [] ctx in
  let new_todo, set_new_todo = use_state "" ctx in
  
  let add_todo = fun () ->
    if get_value new_todo <> "" then (
      set_todos ((get_value new_todo) :: get_value todos);
      set_new_todo ""
    )
  in
  
  let todo_items = List.map (fun todo ->
    create_element "li" [] [create_text todo]
  ) (get_value todos) in
  
  create_element "div" [] [
    create_element "h1" [] [create_text "Todo List"];
    create_element "input" [
      String ("placeholder", "Enter new todo");
      String ("value", get_value new_todo);
      on_input set_new_todo
    ] [];
    create_element "button" [on_click add_todo] [create_text "Add Todo"];
    create_element "ul" [] todo_items;
  ]

(* Main application *)
let app (ctx: context) : element =
  create_element "div" [] [
    create_element "h1" [] [create_text "Reactive UI DSL Demo"];
    create_component (fun () -> counter_component ctx);
    create_component (fun () -> todo_component ctx);
  ]
```

## Advanced Features

Let's add some advanced features to make our DSL more powerful:

```ocaml
(* Advanced features *)

(* Conditional rendering *)
let when_ (condition: bool) (element: element) : element =
  if condition then element else create_text ""

(* List rendering *)
let map (f: 'a -> element) (list: 'a list) : element list =
  List.map f list

(* CSS classes *)
let class_name (name: string) : attribute =
  String ("class", name)

let id (id: string) : attribute =
  String ("id", id)

(* Styling *)
let style (styles: (string * string) list) : attribute =
  let style_str = String.concat "; " (List.map (fun (k, v) -> k ^ ": " ^ v) styles) in
  String ("style", style_str)

(* Example with advanced features *)
let advanced_counter (ctx: context) : element =
  let count, set_count = use_state 0 ctx in
  let is_even = (get_value count) mod 2 = 0 in
  
  create_element "div" [
    class_name "counter-container";
    style [("padding", "20px"); ("border", "1px solid #ccc")]
  ] [
    create_element "h2" [] [create_text "Advanced Counter"];
    create_element "p" [
      class_name (if is_even then "even" else "odd")
    ] [create_text (Printf.sprintf "Count: %d" (get_value count))];
    when_ is_even (create_element "p" [] [create_text "Even number!"]);
    create_element "button" [
      on_click (fun () -> set_count (get_value count + 1))
    ] [create_text "Increment"];
  ]
```

## Build Instructions

To use this DSL in your OCaml project, create a `dune` file:

```ocaml
(* dune *)
(executable
 (name main)
 (libraries))
```

And a `dune-project` file:

```ocaml
(lang dune 3.0)
```

To build and run:

```bash
dune build
dune exec ./main.exe
```

## Complete Example

Here's a complete working example:

```ocaml
(* main.ml *)
open Reactive_ui

let () =
  let ctx = create_context () in
  let app_element = app ctx in
  let html = render app_element in
  print_endline html
```

## Key Benefits

Our OCaml reactive DSL provides several advantages:

1. **Type Safety**: OCaml's type system catches errors at compile time
2. **Functional Composition**: Components are pure functions that compose naturally
3. **Immutability**: State changes are explicit and traceable
4. **Performance**: Virtual DOM diffing can be optimized
5. **Expressiveness**: Pattern matching and algebraic data types make UI logic clear

## Conclusion

This tutorial demonstrated how to build a simple reactive DSL for UI applications in OCaml. While this is a basic implementation, it showcases the core concepts that make frameworks like React powerful:

- Virtual DOM representation
- Component-based architecture
- State management with hooks
- Event handling
- Functional composition

The OCaml version adds type safety and functional programming benefits that can help build more robust UI applications. You can extend this DSL with features like:

- More sophisticated diffing algorithms
- CSS-in-OCaml solutions
- Server-side rendering
- Animation support
- Developer tools

The functional nature of OCaml makes it an excellent choice for building reactive UI frameworks that are both powerful and maintainable.

---

*This tutorial provides a foundation for understanding reactive UI frameworks. The code examples are simplified for educational purposes, but they demonstrate the core concepts that make modern UI frameworks work.*