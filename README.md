# Virtual DOM in OCaml

This repository contains a complete implementation of a Virtual DOM system in OCaml, demonstrating how functional programming principles can be applied to frontend development.

## Overview

The Virtual DOM is a programming concept where an ideal, or "virtual", representation of a UI is kept in memory and synced with the "real" DOM by a library such as ReactDOM. This process is called reconciliation.

Our OCaml implementation provides:

- **Type-safe virtual DOM trees** with algebraic data types
- **Efficient diffing algorithms** for minimal DOM updates
- **Component system** with state management
- **Immutable data structures** for predictable updates
- **Performance optimizations** including memoization

## Files

- `virtual_dom.ml` - Core virtual DOM data structures and algorithms
- `todo_app.ml` - Complete todo application example
- `performance_test.ml` - Benchmarks and performance testing
- `dom_renderer.ml` - Browser DOM integration
- `index.html` - Demo web page

## Building and Running

### Prerequisites

- OCaml 4.14 or later
- Dune build system
- js_of_ocaml (for browser compilation)

### Build Commands

```bash
# Install dependencies
opam install dune js_of_ocaml

# Build the project
dune build

# Run the virtual DOM example
dune exec ./virtual_dom.exe

# Run the todo application
dune exec ./todo_app.exe

# Run performance tests
dune exec ./performance_test.exe

# Compile for browser
dune build virtual_dom_js.js
```

### Browser Demo

1. Compile the JavaScript version:
   ```bash
   dune build virtual_dom_js.js
   ```

2. Open `index.html` in a web browser

## Key Features

### 1. Virtual DOM Trees

```ocaml
let example = 
  div [("class", "container")]
    [
      h1 [] [create_text "Hello, World!"];
      button [("onclick", "handleClick")] [create_text "Click me!"]
    ]
```

### 2. Efficient Diffing

The diff algorithm compares virtual DOM trees and produces minimal update operations:

```ocaml
let diff_result = diff old_tree new_tree 0
(* Returns: { operations = [(0, Update new_element)]; new_tree = new_tree } *)
```

### 3. Component System

```ocaml
let counter_component =
  let render props state = (* ... *) in
  let update props state = (* ... *) in
  create_component "Counter" render update
```

### 4. Performance Optimizations

- **Memoization**: Cache expensive component renders
- **Shallow comparison**: Only diff when necessary
- **Key-based reconciliation**: Efficient list updates
- **Batched operations**: Group DOM updates

## Performance

Our implementation demonstrates excellent performance characteristics:

- **O(n) diff complexity** where n is the number of nodes
- **Memory efficient** with immutable data structures
- **Type safety** prevents runtime errors
- **Compiled optimization** through OCaml's compiler

## Architecture

The system is built around several core concepts:

1. **Virtual DOM Trees**: Immutable tree structures representing UI
2. **Diffing Algorithm**: Compares trees to find minimal changes
3. **Component System**: Encapsulates UI logic and state
4. **DOM Renderer**: Applies changes to the actual browser DOM
5. **Event System**: Handles user interactions

## Examples

### Simple Counter

```ocaml
let counter = 
  div []
    [
      create_text ("Count: " ^ string_of_int count);
      button [("onclick", "increment")] [create_text "+"]
    ]
```

### Todo List

```ocaml
let todo_list todos =
  ul []
    (List.map (fun todo ->
      li [("class", if todo.completed then "completed" else "")]
        [
          create_text todo.text;
          button [("onclick", "delete")] [create_text "Delete"]
        ]
    ) todos)
```

## Learning Resources

This implementation demonstrates several important concepts:

- **Functional Programming**: Pure functions and immutable data
- **Type Systems**: Algebraic data types and pattern matching
- **Algorithms**: Tree diffing and reconciliation
- **Performance**: Optimization techniques and benchmarking
- **Frontend Architecture**: Component-based UI development

## Contributing

This is an educational project demonstrating virtual DOM concepts in OCaml. Contributions that improve clarity, add examples, or enhance performance are welcome.

## License

This project is open source and available under the MIT License.