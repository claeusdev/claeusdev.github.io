---
layout: "post"
date: 2025-01-15
title: "Building a Type Inference Engine for JavaScript in OCaml: Fundamentals"
categories: "language-design"
draft: false
---

Type inference is one of the most elegant features of modern programming languages. It allows programmers to write code without explicit type annotations while still maintaining type safety. In this series, we'll build a complete type inference engine for JavaScript using OCaml, exploring the theoretical foundations and practical implementation details.

## What is Type Inference?

Type inference is the process of automatically determining the types of expressions in a program without explicit type annotations. Consider this JavaScript-like code:

```javascript
function add(x, y) {
    return x + y;
}

const result = add(5, 3);
```

A type inference engine should be able to determine that:
- `x` and `y` are both numbers
- `add` has type `(number, number) -> number`
- `result` has type `number`

This process happens at compile time, allowing us to catch type errors before the program runs while keeping the code clean and readable.

## Why OCaml for Type Inference?

OCaml is particularly well-suited for implementing type inference engines for several reasons:

1. **Algebraic Data Types**: Perfect for representing abstract syntax trees and type expressions
2. **Pattern Matching**: Elegant handling of complex type rules
3. **Type System**: OCaml's own type system helps catch errors in our inference engine
4. **Functional Programming**: Natural fit for the mathematical nature of type theory
5. **Performance**: Compiled to efficient native code

## The Hindley-Milner Type System

Our type inference engine will be based on the Hindley-Milner type system, named after J. Roger Hindley and Robin Milner. This system provides:

- **Polymorphic types**: Functions can work with multiple types
- **Type variables**: Placeholders for unknown types
- **Unification**: The process of finding consistent type assignments
- **Generalization**: Making types polymorphic when appropriate

## Core Concepts

### Type Expressions

In our system, types are represented as expressions that can be:

```ocaml
type ty =
  | TyVar of string          (* Type variable: 'a, 'b, etc. *)
  | TyCon of string          (* Type constructor: int, bool, etc. *)
  | TyArrow of ty * ty       (* Function type: 'a -> 'b *)
  | TyTuple of ty list       (* Tuple type: ('a, 'b) *)
  | TyList of ty             (* List type: 'a list *)
```

### Type Schemes

A type scheme generalizes a type by quantifying over type variables:

```ocaml
type scheme = Scheme of string list * ty
```

For example, `∀'a. 'a -> 'a` is a type scheme where `'a` is universally quantified.

### Type Environment

The type environment (or context) maps variables to their type schemes:

```ocaml
type env = (string * scheme) list
```

## The Unification Algorithm

The heart of type inference is unification—the process of finding a substitution that makes two types equal. Here's how it works:

```ocaml
exception Unify of ty * ty

let rec unify t1 t2 =
  match (t1, t2) with
  | (TyVar x, TyVar y) when x = y -> []
  | (TyVar x, t) when not (occurs x t) -> [(x, t)]
  | (t, TyVar x) when not (occurs x t) -> [(x, t)]
  | (TyArrow (t1, t2), TyArrow (t1', t2')) ->
      let s1 = unify t1 t1' in
      let s2 = unify (subst s1 t2) (subst s1 t2') in
      compose s1 s2
  | (TyCon x, TyCon y) when x = y -> []
  | (t1, t2) -> raise (Unify (t1, t2))
```

The `occurs` check prevents infinite types:

```ocaml
let rec occurs x t =
  match t with
  | TyVar y -> x = y
  | TyCon _ -> false
  | TyArrow (t1, t2) -> occurs x t1 || occurs x t2
  | TyTuple ts -> List.exists (occurs x) ts
  | TyList t -> occurs x t
```

## A Simple Expression Language

Let's start with a minimal language to demonstrate type inference:

```ocaml
type expr =
  | Var of string
  | Int of int
  | Bool of bool
  | Add of expr * expr
  | If of expr * expr * expr
  | Fun of string * expr
  | App of expr * expr
  | Let of string * expr * expr
```

This language includes:
- Variables and literals
- Arithmetic operations
- Conditionals
- Functions and applications
- Let bindings

## The Type Inference Algorithm

The main type inference function takes an expression and an environment, returning a type and a substitution:

```ocaml
let rec infer env expr =
  match expr with
  | Var x -> 
      let Scheme (vars, t) = lookup x env in
      (instantiate vars t, [])
  
  | Int _ -> (TyCon "int", [])
  | Bool _ -> (TyCon "bool", [])
  
  | Add (e1, e2) ->
      let (t1, s1) = infer env e1 in
      let (t2, s2) = infer (subst_env s1 env) e2 in
      let s3 = unify (subst s2 t1) (TyCon "int") in
      let s4 = unify (subst s3 t2) (TyCon "int") in
      (TyCon "int", compose s1 (compose s2 (compose s3 s4)))
  
  | If (e1, e2, e3) ->
      let (t1, s1) = infer env e1 in
      let s2 = unify (subst s1 t1) (TyCon "bool") in
      let (t2, s3) = infer (subst_env (compose s1 s2) env) e2 in
      let (t3, s4) = infer (subst_env (compose s1 (compose s2 s3)) env) e3 in
      let s5 = unify (subst s4 t2) t3 in
      (subst s5 t2, compose s1 (compose s2 (compose s3 (compose s4 s5))))
  
  | Fun (x, e) ->
      let a = fresh_var () in
      let env' = (x, Scheme ([], a)) :: env in
      let (t, s) = infer env' e in
      (TyArrow (subst s a, t), s)
  
  | App (e1, e2) ->
      let (t1, s1) = infer env e1 in
      let (t2, s2) = infer (subst_env s1 env) e2 in
      let a = fresh_var () in
      let s3 = unify (subst s2 t1) (TyArrow (t2, a)) in
      (subst s3 a, compose s1 (compose s2 s3))
  
  | Let (x, e1, e2) ->
      let (t1, s1) = infer env e1 in
      let t1' = subst s1 t1 in
      let env' = subst_env s1 env in
      let (t2, s2) = infer ((x, generalize env' t1') :: env') e2 in
      (t2, compose s1 s2)
```

## Helper Functions

We need several helper functions to make this work:

```ocaml
let fresh_var_counter = ref 0

let fresh_var () =
  incr fresh_var_counter;
  TyVar ("'a" ^ string_of_int !fresh_var_counter)

let lookup x env =
  try List.assoc x env
  with Not_found -> failwith ("Unbound variable: " ^ x)

let instantiate vars t =
  let subst = List.map (fun v -> (v, fresh_var ())) vars in
  subst_list subst t

let generalize env t =
  let fv_t = free_vars t in
  let fv_env = free_vars_env env in
  let vars = List.filter (fun v -> not (List.mem v fv_env)) fv_t in
  Scheme (vars, t)

let subst_env s env =
  List.map (fun (x, scheme) -> (x, subst_scheme s scheme)) env

let subst_scheme s (Scheme (vars, t)) =
  let s' = List.filter (fun (v, _) -> not (List.mem v vars)) s in
  Scheme (vars, subst_list s' t)
```

## Example: Type Inference in Action

Let's trace through the type inference of a simple function:

```ocaml
(* fun x -> x + 1 *)
let expr = Fun ("x", Add (Var "x", Int 1))
```

The inference process:

1. **Function body**: `Add (Var "x", Int 1)`
   - `Var "x"` gets type `'a` (from environment)
   - `Int 1` gets type `int`
   - `Add` requires both operands to be `int`
   - Unification: `'a` = `int`, so `'a` becomes `int`
   - Result: `int`

2. **Function type**: `'a -> int` where `'a` = `int`
   - Final type: `int -> int`

## Error Handling

Our type inference engine should provide meaningful error messages:

```ocaml
exception TypeError of string

let type_error msg = raise (TypeError msg)

let rec infer env expr =
  try
    (* ... existing inference code ... *)
  with
  | Unify (t1, t2) -> 
      type_error ("Cannot unify types " ^ string_of_ty t1 ^ 
                  " and " ^ string_of_ty t2)
  | Not_found -> 
      type_error ("Unbound variable")
```

## Testing Our Implementation

Let's create some test cases to verify our type inference engine:

```ocaml
let test_cases = [
  ("5", "int");
  ("true", "bool");
  ("fun x -> x", "'a -> 'a");
  ("fun x -> x + 1", "int -> int");
  ("fun x y -> x", "'a -> 'b -> 'a");
  ("let id = fun x -> x in id 5", "int");
]

let run_tests () =
  List.iter (fun (expr_str, expected) ->
    try
      let expr = parse expr_str in
      let (ty, _) = infer [] expr in
      let ty_str = string_of_ty ty in
      Printf.printf "✓ %s : %s\n" expr_str ty_str
    with
    | TypeError msg -> Printf.printf "✗ %s: %s\n" expr_str msg
  ) test_cases
```

## What We've Built

In this first part, we've established the theoretical foundation for our type inference engine:

1. **Type System**: Hindley-Milner with type variables, constructors, and arrows
2. **Unification**: Algorithm for finding consistent type assignments
3. **Inference Rules**: Systematic approach to type inference
4. **Error Handling**: Meaningful error messages for type errors

## Next Steps

In the next part of this series, we'll:

1. **Extend the language** with more JavaScript-like features
2. **Implement advanced type features** like generics and modules
3. **Add JavaScript-specific constructs** like objects and arrays
4. **Optimize performance** for large programs
5. **Build a complete tool** that can analyze real JavaScript code

The foundation we've built here provides the mathematical rigor needed for a robust type inference engine. The Hindley-Milner system gives us polymorphic types, and our unification algorithm ensures type consistency.

Type inference is a beautiful example of how mathematical theory translates into practical programming tools. By understanding these fundamentals, we can build type systems that make programming safer and more expressive.

In our next article, we'll dive deeper into the Hindley-Milner system and implement more sophisticated type inference features that will bring us closer to a complete JavaScript type checker.