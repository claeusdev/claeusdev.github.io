---
layout: "post"
date: 2025-02-05
title: "Building a Type Inference Engine for JavaScript in OCaml: Advanced Features"
categories: "language-design"
draft: false
---

In our previous articles, we built a comprehensive type inference engine that can handle JavaScript's dynamic nature. Now we'll explore advanced features that make our engine production-ready: generics with constraints, module systems, performance optimizations, and integration with existing tools.

## Generic Types and Constraints

Generic types allow us to write reusable code that works with multiple types while maintaining type safety. Let's extend our type system to support them:

```ocaml
(* Extended type system with generics *)
type js_ty =
  | JsVar of string
  | JsPrim of string
  | JsObject of object_type
  | JsFunction of js_ty list * js_ty
  | JsArray of js_ty
  | JsUnion of js_ty list
  | JsIntersection of js_ty list
  | JsOptional of js_ty
  | JsIndex of js_ty * js_ty
  | JsGeneric of string * js_ty list
  | JsThis of js_ty
  | JsNever
  | JsAny
  | JsGenericVar of string  (* Generic type variable *)

(* Type constraints *)
type constraint_ =
  | Eq of js_ty * js_ty
  | Subtype of js_ty * js_ty
  | HasProperty of js_ty * string * js_ty
  | HasMethod of js_ty * string * js_ty list * js_ty
  | IsArray of js_ty
  | IsFunction of js_ty
  | IsObject of js_ty

(* Generic type definitions *)
type generic_def = {
  name: string;
  parameters: string list;
  constraints: constraint_ list;
  body: js_ty;
}

(* Type scheme with constraints *)
type scheme = Scheme of string list * constraint_ list * js_ty
```

## Constraint Solving

The key to generic types is constraint solving. We need to find type assignments that satisfy all constraints:

```ocaml
let rec solve_constraints constraints =
  let rec solve cs acc =
    match cs with
    | [] -> acc
    | Eq (t1, t2)::cs ->
        let s = unify t1 t2 in
        let cs' = List.map (fun c -> subst_constraint s c) cs in
        solve cs' (compose acc s)
    | Subtype (t1, t2)::cs ->
        let s = check_subtype t1 t2 in
        let cs' = List.map (fun c -> subst_constraint s c) cs in
        solve cs' (compose acc s)
    | HasProperty (obj, prop, ty)::cs ->
        let s = check_property obj prop ty in
        let cs' = List.map (fun c -> subst_constraint s c) cs in
        solve cs' (compose acc s)
    | HasMethod (obj, method_name, params, ret)::cs ->
        let s = check_method obj method_name params ret in
        let cs' = List.map (fun c -> subst_constraint s c) cs in
        solve cs' (compose acc s)
    | IsArray (t)::cs ->
        let s = unify t (JsArray (fresh_var ())) in
        let cs' = List.map (fun c -> subst_constraint s c) cs in
        solve cs' (compose acc s)
    | IsFunction (t)::cs ->
        let s = unify t (JsFunction ([], fresh_var ())) in
        let cs' = List.map (fun c -> subst_constraint s c) cs in
        solve cs' (compose acc s)
    | IsObject (t)::cs ->
        let s = unify t (JsObject { properties = []; index_signature = None; prototype = None; call_signature = None; construct_signature = None }) in
        let cs' = List.map (fun c -> subst_constraint s c) cs in
        solve cs' (compose acc s)
  in
  solve constraints []

and subst_constraint s c =
  match c with
  | Eq (t1, t2) -> Eq (subst s t1, subst s t2)
  | Subtype (t1, t2) -> Subtype (subst s t1, subst s t2)
  | HasProperty (obj, prop, ty) -> HasProperty (subst s obj, prop, subst s ty)
  | HasMethod (obj, method_name, params, ret) -> 
      HasMethod (subst s obj, method_name, List.map (subst s) params, subst s ret)
  | IsArray (t) -> IsArray (subst s t)
  | IsFunction (t) -> IsFunction (subst s t)
  | IsObject (t) -> IsObject (subst s t)
```

## Generic Type Inference

Now let's implement type inference for generic types:

```ocaml
let rec infer_generic env expr =
  match expr with
  | JsGenericCall (name, args) ->
      let generic_def = lookup_generic name env in
      let (arg_types, s1) = infer_list env args in
      let constraints = List.map2 (fun param arg_ty ->
        Eq (JsGenericVar param, arg_ty)
      ) generic_def.parameters arg_types in
      let s2 = solve_constraints (generic_def.constraints @ constraints) in
      let body_ty = subst s2 generic_def.body in
      (body_ty, compose s1 s2)
  
  | JsGenericDef (name, params, constraints, body) ->
      let generic_def = {
        name;
        parameters = params;
        constraints;
        body;
      } in
      let env' = (name, GenericScheme generic_def) :: env in
      (JsGeneric (name, List.map (fun _ -> fresh_var ()) params), [])
  
  | JsConstraint (expr, constraint_) ->
      let (ty, s1) = infer_generic env expr in
      let s2 = solve_constraints [constraint_] in
      (ty, compose s1 s2)
  
  | JsTypeAssertion (expr, ty) ->
      let (expr_ty, s1) = infer_generic env expr in
      let s2 = unify expr_ty ty in
      (ty, compose s1 s2)
  
  | _ -> infer_js env expr  (* Fall back to regular inference *)
```

## Module System

A module system allows us to organize code into separate units with controlled interfaces:

```ocaml
(* Module system types *)
type module_ty = {
  name: string;
  exports: (string * scheme) list;
  imports: (string * string * scheme) list;  (* (local_name, module_name, scheme) *)
  dependencies: string list;
}

type module_env = (string * module_ty) list

(* Module expressions *)
type module_expr =
  | ModuleDef of string * module_expr list
  | ModuleImport of string * string option * string list  (* (module, alias, names) *)
  | ModuleExport of string * js_expr
  | ModuleReExport of string * string list
  | ModuleNamespace of string

let rec infer_module env module_expr =
  match module_expr with
  | ModuleDef (name, body) ->
      let (exports, imports, s) = infer_module_body env body in
      let module_ty = {
        name;
        exports;
        imports;
        dependencies = List.map (fun (_, module_name, _) -> module_name) imports;
      } in
      (module_ty, s)
  
  | ModuleImport (module_name, alias, names) ->
      let module_ty = lookup_module module_name env in
      let imports = List.map (fun name ->
        let scheme = List.assoc name module_ty.exports in
        (name, module_name, scheme)
      ) names in
      (imports, [])
  
  | ModuleExport (name, expr) ->
      let (ty, s) = infer_js env expr in
      let scheme = generalize env ty in
      ([(name, scheme)], s)
  
  | ModuleReExport (module_name, names) ->
      let module_ty = lookup_module module_name env in
      let exports = List.map (fun name ->
        let scheme = List.assoc name module_ty.exports in
        (name, scheme)
      ) names in
      (exports, [])
  
  | ModuleNamespace (name) ->
      let module_ty = lookup_module name env in
      let namespace_ty = JsObject {
        properties = List.map (fun (name, scheme) ->
          (name, { ty = instantiate scheme; optional = false; readonly = false; getter = None; setter = None })
        ) module_ty.exports;
        index_signature = None;
        prototype = None;
        call_signature = None;
        construct_signature = None;
      } in
      (namespace_ty, [])

and infer_module_body env body =
  let rec infer_items items acc_exports acc_imports acc_s =
    match items with
    | [] -> (acc_exports, acc_imports, acc_s)
    | item::items ->
        let (exports, imports, s) = infer_module env item in
        let new_exports = acc_exports @ exports in
        let new_imports = acc_imports @ imports in
        let new_s = compose acc_s s in
        infer_items items new_exports new_imports new_s
  in
  infer_items body [] [] []
```

## Performance Optimizations

For large codebases, we need to optimize our type inference engine:

### Union-Find for Unification

```ocaml
module UnionFind = struct
  type 'a node = 
    | Root of 'a ref
    | Link of 'a node ref
  
  let create x = Root (ref x)
  
  let rec find = function
    | Root r -> r
    | Link r -> find !r
  
  let union x y =
    let rx = find x in
    let ry = find y in
    if rx == ry then ()
    else rx := !ry
end

(* Optimized unification with union-find *)
let rec unify_optimized t1 t2 =
  let rec unify_aux t1 t2 =
    match (t1, t2) with
    | (TyVar x, TyVar y) when x = y -> []
    | (TyVar x, t) when not (occurs x t) -> [(x, t)]
    | (t, TyVar x) when not (occurs x t) -> [(x, t)]
    | (TyCon x, TyCon y) when x = y -> []
    | (TyArrow (t1, t2), TyArrow (t1', t2')) ->
        let s1 = unify_aux t1 t1' in
        let s2 = unify_aux (subst s1 t2) (subst s1 t2') in
        compose s1 s2
    | (t1, t2) -> raise (Unify (t1, t2))
  in
  unify_aux t1 t2
```

### Memoization

```ocaml
let memoize f =
  let cache = Hashtbl.create 1000 in
  fun x ->
    try Hashtbl.find cache x
    with Not_found ->
      let result = f x in
      Hashtbl.add cache x result;
      result

(* Memoized type inference *)
let infer_memoized = memoize (fun (env, expr) ->
  infer_js env expr
)
```

### Incremental Type Checking

```ocaml
type incremental_state = {
  cache: (string * scheme) list;
  dependencies: (string * string list) list;
  dirty: string list;
}

let incremental_infer state env expr =
  let (ty, s) = infer_js env expr in
  let new_state = {
    cache = List.map (fun (name, scheme) -> (name, subst_scheme s scheme)) state.cache;
    dependencies = state.dependencies;
    dirty = List.filter (fun name -> List.mem name state.dirty) (free_vars ty);
  } in
  (ty, s, new_state)
```

## Integration with TypeScript

To make our engine useful, we need to integrate with existing tools:

```ocaml
(* TypeScript compatibility *)
type ts_ty =
  | TSPrim of string
  | TSObject of (string * ts_ty) list
  | TSFunction of ts_ty list * ts_ty
  | TSArray of ts_ty
  | TSUnion of ts_ty list
  | TSIntersection of ts_ty list
  | TSGeneric of string * ts_ty list
  | TSLiteral of string
  | TSNever
  | TSAny

let js_ty_to_ts_ty js_ty =
  match js_ty with
  | JsPrim p -> TSPrim p
  | JsObject obj -> 
      TSObject (List.map (fun (name, prop) -> (name, js_ty_to_ts_ty prop.ty)) obj.properties)
  | JsFunction (params, ret) -> 
      TSFunction (List.map js_ty_to_ts_ty params, js_ty_to_ts_ty ret)
  | JsArray t -> TSArray (js_ty_to_ts_ty t)
  | JsUnion ts -> TSUnion (List.map js_ty_to_ts_ty ts)
  | JsIntersection ts -> TSIntersection (List.map js_ty_to_ts_ty ts)
  | JsGeneric (name, args) -> TSGeneric (name, List.map js_ty_to_ts_ty args)
  | JsNever -> TSNever
  | JsAny -> TSAny
  | _ -> TSAny

let generate_ts_declarations module_ty =
  let exports = List.map (fun (name, scheme) ->
    let ty = instantiate scheme in
    let ts_ty = js_ty_to_ts_ty ty in
    Printf.sprintf "export declare const %s: %s;" name (string_of_ts_ty ts_ty)
  ) module_ty.exports in
  String.concat "\n" exports

and string_of_ts_ty t =
  match t with
  | TSPrim p -> p
  | TSObject fields ->
      let field_strs = List.map (fun (name, ty) -> 
        name ^ ": " ^ string_of_ts_ty ty
      ) fields in
      "{" ^ String.concat ", " field_strs ^ "}"
  | TSFunction (params, ret) ->
      let param_strs = List.map string_of_ts_ty params in
      "(" ^ String.concat ", " param_strs ^ ") => " ^ string_of_ts_ty ret
  | TSArray t -> string_of_ts_ty t ^ "[]"
  | TSUnion ts -> String.concat " | " (List.map string_of_ts_ty ts)
  | TSIntersection ts -> String.concat " & " (List.map string_of_ts_ty ts)
  | TSGeneric (name, args) ->
      let arg_strs = List.map string_of_ts_ty args in
      name ^ "<" ^ String.concat ", " arg_strs ^ ">"
  | TSLiteral s -> "\"" ^ s ^ "\""
  | TSNever -> "never"
  | TSAny -> "any"
```

## Real-World Testing

Let's create comprehensive tests for our advanced features:

```ocaml
let advanced_test_cases = [
  (* Generic types *)
  ("function identity<T>(x: T): T { return x; }", "identity: <T>(x: T) => T");
  ("identity<number>(42)", "number");
  ("identity<string>('hello')", "string");
  
  (* Generic constraints *)
  ("function length<T extends Array<any>>(arr: T): number { return arr.length; }", "length: <T extends Array<any>>(arr: T) => number");
  ("length([1, 2, 3])", "number");
  
  (* Module system *)
  ("module Math { export function add(x: number, y: number): number { return x + y; } }", "Math: { add: (x: number, y: number) => number }");
  ("import { add } from 'Math'", "add: (x: number, y: number) => number");
  
  (* Union types *)
  ("function process(x: string | number): string { return String(x); }", "process: (x: string | number) => string");
  ("process('hello')", "string");
  ("process(42)", "string");
  
  (* Intersection types *)
  ("function combine<T, U>(x: T, y: U): T & U { return Object.assign(x, y); }", "combine: <T, U>(x: T, y: U) => T & U");
  
  (* Optional types *)
  ("function greet(name?: string): string { return name ? `Hello, ${name}!` : 'Hello!'; }", "greet: (name?: string) => string");
  ("greet()", "string");
  ("greet('Alice')", "string");
  
  (* Index signatures *)
  ("function getValue(obj: {[key: string]: any}, key: string): any { return obj[key]; }", "getValue: (obj: {[key: string]: any}, key: string) => any");
  
  (* Async/await *)
  ("async function fetchData(): Promise<string> { return 'data'; }", "fetchData: () => Promise<string>");
  ("await fetchData()", "string");
  
  (* Classes with generics *)
  ("class Container<T> { constructor(public value: T) {} }", "Container: <T>(value: T) => Container<T>");
  ("new Container<number>(42)", "Container<number>");
]

let run_advanced_tests () =
  Printf.printf "Running advanced type inference tests:\n\n";
  List.iter (fun (expr_str, expected) ->
    try
      let expr = parse_js expr_str in
      let (ty, _) = infer_generic [] expr in
      let ty_str = string_of_js_ty ty in
      Printf.printf "✓ %s : %s\n" expr_str ty_str;
      if ty_str = expected then
        Printf.printf "  ✓ Expected: %s\n" expected
      else
        Printf.printf "  ⚠ Expected: %s, got: %s\n" expected ty_str
    with
    | e -> 
        Printf.printf "✗ %s: %s\n" expr_str (Printexc.to_string e)
  ) advanced_test_cases
```

## Error Recovery and Suggestions

A production type inference engine should provide helpful error messages and suggestions:

```ocaml
type error_suggestion =
  | TypeSuggestion of js_ty
  | PropertySuggestion of string
  | MethodSuggestion of string
  | ImportSuggestion of string

let suggest_fixes error =
  match error with
  | JsTypeError (msg, t1, t2) ->
      let suggestions = [
        TypeSuggestion t1;
        TypeSuggestion t2;
      ] in
      (msg, suggestions)
  | JsPropertyError (obj, prop) ->
      let suggestions = [
        PropertySuggestion prop;
        MethodSuggestion prop;
      ] in
      (Printf.sprintf "Property '%s' not found on type %s" prop (string_of_js_ty obj), suggestions)
  | JsCoercionError (from, to) ->
      let suggestions = [
        TypeSuggestion from;
        TypeSuggestion to;
      ] in
      (Printf.sprintf "Cannot convert %s to %s" (string_of_js_ty from) (string_of_js_ty to), suggestions)
  | _ -> ("Unknown error", [])

let format_error_with_suggestions error =
  let (msg, suggestions) = suggest_fixes error in
  let suggestion_strs = List.map (fun s ->
    match s with
    | TypeSuggestion ty -> "Consider using type: " ^ string_of_js_ty ty
    | PropertySuggestion prop -> "Did you mean property: " ^ prop
    | MethodSuggestion method -> "Did you mean method: " ^ method
    | ImportSuggestion module_name -> "Did you mean to import from: " ^ module_name
  ) suggestions in
  msg ^ "\nSuggestions:\n" ^ String.concat "\n" suggestion_strs
```

## Performance Benchmarks

Let's measure the performance of our type inference engine:

```ocaml
let benchmark_type_inference expr =
  let start_time = Sys.time () in
  let (ty, s) = infer_js [] expr in
  let end_time = Sys.time () in
  let duration = end_time -. start_time in
  Printf.printf "Type inference took %.4f seconds\n" duration;
  (ty, s)

let benchmark_large_program () =
  let large_expr = generate_large_program 1000 in  (* 1000 expressions *)
  let (ty, s) = benchmark_type_inference large_expr in
  Printf.printf "Inferred type: %s\n" (string_of_js_ty ty)

let generate_large_program size =
  let rec generate n acc =
    if n <= 0 then acc
    else
      let expr = JsBinary (JsAdd, JsNumber (float n), JsNumber (float (n - 1))) in
      generate (n - 1) (expr :: acc)
  in
  let exprs = generate size [] in
  List.fold_left (fun acc expr -> JsBinary (JsAdd, acc, expr)) (JsNumber 0.0) exprs
```

## What We've Accomplished

In this final article, we've built a production-ready type inference engine with:

1. **Generic types and constraints** for reusable, type-safe code
2. **Module system** for organizing large codebases
3. **Performance optimizations** for handling real-world programs
4. **TypeScript integration** for compatibility with existing tools
5. **Error recovery and suggestions** for better developer experience
6. **Comprehensive testing** to ensure correctness

## The Complete Picture

Our type inference engine now provides:

- **Mathematical rigor** from Hindley-Milner foundations
- **JavaScript compatibility** with dynamic typing and prototypes
- **Advanced features** like generics and modules
- **Production readiness** with performance optimizations
- **Tool integration** with TypeScript and other systems

## The Journey

Building a type inference engine is a journey through:

1. **Type theory** - Understanding the mathematical foundations
2. **Language design** - Adapting theory to practical needs
3. **Implementation** - Turning theory into working code
4. **Optimization** - Making it fast enough for real use
5. **Integration** - Connecting with existing tools and workflows

## Conclusion

Type inference is one of the most elegant features of modern programming languages. By building our own engine, we've gained deep understanding of:

- How type systems work mathematically
- Why some designs are better than others
- How to balance expressiveness with performance
- What makes a good developer experience

The Hindley-Milner system we started with provides the mathematical foundation, but JavaScript's dynamic nature required us to extend it significantly. The result is a type inference engine that can handle real-world JavaScript code while maintaining the elegance and correctness of the underlying theory.

This series has shown how mathematical theory translates into practical programming tools. By understanding the fundamentals, we can build systems that make programming safer, more expressive, and more enjoyable.

The type inference engine we've built is not just a tool—it's a demonstration of how beautiful mathematics can create beautiful software. And that's the true power of type theory: it gives us the tools to build better programming languages and better programming experiences.