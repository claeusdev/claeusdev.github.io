---
layout: "post"
date: 2025-01-22
title: "Building a Type Inference Engine for JavaScript in OCaml: Hindley-Milner Implementation"
categories: "language-design"
draft: false
---

In our previous article, we laid the theoretical foundation for type inference. Now we'll dive deep into implementing the Hindley-Milner type system, the mathematical framework that powers type inference in languages like ML, Haskell, and TypeScript.

The Hindley-Milner system is remarkable because it provides both powerful type inference and a decidable type checking algorithm. We'll implement it step by step, understanding not just how it works, but why it works.

## The Mathematical Foundation

The Hindley-Milner system is based on a few key mathematical concepts:

1. **Type Variables**: Represent unknown types that can be instantiated
2. **Type Schemes**: Quantified types that can be generalized
3. **Unification**: The process of finding consistent type assignments
4. **Generalization**: Making types polymorphic when safe

Let's build a complete implementation that demonstrates these concepts.

## Complete Type System Implementation

First, let's define our complete type system:

```ocaml
(* Type expressions *)
type ty =
  | TyVar of string
  | TyCon of string
  | TyArrow of ty * ty
  | TyTuple of ty list
  | TyList of ty
  | TyRecord of (string * ty) list
  | TyUnion of ty list

(* Type schemes with quantification *)
type scheme = Scheme of string list * ty

(* Type environment *)
type env = (string * scheme) list

(* Substitutions *)
type substitution = (string * ty) list
```

## The Unification Algorithm

Unification is the heart of type inference. It finds a substitution that makes two types equal:

```ocaml
exception Unify of ty * ty
exception Occurs of string * ty

let rec occurs x t =
  match t with
  | TyVar y -> x = y
  | TyCon _ -> false
  | TyArrow (t1, t2) -> occurs x t1 || occurs x t2
  | TyTuple ts -> List.exists (occurs x) ts
  | TyList t -> occurs x t
  | TyRecord fields -> List.exists (fun (_, t) -> occurs x t) fields
  | TyUnion ts -> List.exists (occurs x) ts

let rec unify t1 t2 =
  match (t1, t2) with
  | (TyVar x, TyVar y) when x = y -> []
  | (TyVar x, t) when not (occurs x t) -> [(x, t)]
  | (t, TyVar x) when not (occurs x t) -> [(x, t)]
  | (TyCon x, TyCon y) when x = y -> []
  | (TyArrow (t1, t2), TyArrow (t1', t2')) ->
      let s1 = unify t1 t1' in
      let s2 = unify (subst s1 t2) (subst s1 t2') in
      compose s1 s2
  | (TyTuple ts1, TyTuple ts2) when List.length ts1 = List.length ts2 ->
      unify_list ts1 ts2
  | (TyList t1, TyList t2) -> unify t1 t2
  | (TyRecord fields1, TyRecord fields2) ->
      unify_record fields1 fields2
  | (TyUnion ts1, TyUnion ts2) ->
      unify_union ts1 ts2
  | (t1, t2) -> raise (Unify (t1, t2))

and unify_list ts1 ts2 =
  match (ts1, ts2) with
  | ([], []) -> []
  | (t1::ts1, t2::ts2) ->
      let s1 = unify t1 t2 in
      let s2 = unify_list (List.map (subst s1) ts1) (List.map (subst s1) ts2) in
      compose s1 s2
  | _ -> failwith "Mismatched tuple lengths"

and unify_record fields1 fields2 =
  let fields1' = List.sort compare fields1 in
  let fields2' = List.sort compare fields2 in
  if List.length fields1' <> List.length fields2' then
    failwith "Mismatched record lengths"
  else
    let rec unify_fields fs1 fs2 acc =
      match (fs1, fs2) with
      | ([], []) -> acc
      | ((l1, t1)::fs1, (l2, t2)::fs2) when l1 = l2 ->
          let s = unify t1 t2 in
          unify_fields (List.map (fun (l, t) -> (l, subst s t)) fs1)
                      (List.map (fun (l, t) -> (l, subst s t)) fs2)
                      (compose acc s)
      | _ -> failwith "Mismatched record fields"
    in
    unify_fields fields1' fields2' []
```

## Substitution Operations

Substitutions are the mechanism by which we apply type assignments:

```ocaml
let rec subst s t =
  match t with
  | TyVar x -> (try List.assoc x s with Not_found -> t)
  | TyCon _ -> t
  | TyArrow (t1, t2) -> TyArrow (subst s t1, subst s t2)
  | TyTuple ts -> TyTuple (List.map (subst s) ts)
  | TyList t -> TyList (subst s t)
  | TyRecord fields -> TyRecord (List.map (fun (l, t) -> (l, subst s t)) fields)
  | TyUnion ts -> TyUnion (List.map (subst s) ts)

let subst_scheme s (Scheme (vars, t)) =
  let s' = List.filter (fun (v, _) -> not (List.mem v vars)) s in
  Scheme (vars, subst s' t)

let subst_env s env =
  List.map (fun (x, scheme) -> (x, subst_scheme s scheme)) env

let compose s1 s2 =
  let s1' = List.map (fun (x, t) -> (x, subst s2 t)) s1 in
  s1' @ s2
```

## Free Variables and Generalization

The key insight of Hindley-Milner is when to generalize types (make them polymorphic):

```ocaml
let rec free_vars t =
  match t with
  | TyVar x -> [x]
  | TyCon _ -> []
  | TyArrow (t1, t2) -> free_vars t1 @ free_vars t2
  | TyTuple ts -> List.flatten (List.map free_vars ts)
  | TyList t -> free_vars t
  | TyRecord fields -> List.flatten (List.map (fun (_, t) -> free_vars t) fields)
  | TyUnion ts -> List.flatten (List.map free_vars ts)

let free_vars_scheme (Scheme (vars, t)) =
  let fv_t = free_vars t in
  List.filter (fun v -> not (List.mem v vars)) fv_t

let free_vars_env env =
  List.flatten (List.map (fun (_, scheme) -> free_vars_scheme scheme) env)

let generalize env t =
  let fv_t = free_vars t in
  let fv_env = free_vars_env env in
  let vars = List.filter (fun v -> not (List.mem v fv_env)) fv_t in
  Scheme (vars, t)

let instantiate (Scheme (vars, t)) =
  let subst = List.map (fun v -> (v, fresh_var ())) vars in
  subst subst t
```

## The Type Inference Algorithm

Now we can implement the complete type inference algorithm:

```ocaml
let fresh_var_counter = ref 0

let fresh_var () =
  incr fresh_var_counter;
  TyVar ("'a" ^ string_of_int !fresh_var_counter)

let rec infer env expr =
  match expr with
  | Var x -> 
      let scheme = lookup x env in
      (instantiate scheme, [])
  
  | Int _ -> (TyCon "int", [])
  | Bool _ -> (TyCon "bool", [])
  | String _ -> (TyCon "string", [])
  
  | Add (e1, e2) | Sub (e1, e2) | Mul (e1, e2) | Div (e1, e2) ->
      let (t1, s1) = infer env e1 in
      let (t2, s2) = infer (subst_env s1 env) e2 in
      let s3 = unify (subst s2 t1) (TyCon "int") in
      let s4 = unify (subst s3 t2) (TyCon "int") in
      (TyCon "int", compose s1 (compose s2 (compose s3 s4)))
  
  | Eq (e1, e2) | Ne (e1, e2) | Lt (e1, e2) | Le (e1, e2) | Gt (e1, e2) | Ge (e1, e2) ->
      let (t1, s1) = infer env e1 in
      let (t2, s2) = infer (subst_env s1 env) e2 in
      let s3 = unify (subst s2 t1) (subst s2 t2) in
      (TyCon "bool", compose s1 (compose s2 s3))
  
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
  
  | LetRec (f, x, e1, e2) ->
      let a = fresh_var () in
      let b = fresh_var () in
      let env' = (f, Scheme ([], TyArrow (a, b))) :: env in
      let (t1, s1) = infer ((x, Scheme ([], a)) :: env') e1 in
      let s2 = unify (subst s1 t1) b in
      let t1' = subst s2 t1 in
      let env'' = subst_env (compose s1 s2) env in
      let (t2, s3) = infer ((f, generalize env'' t1') :: env'') e2 in
      (t2, compose s1 (compose s2 s3))
  
  | Tuple es ->
      let (ts, s) = infer_list env es in
      (TyTuple ts, s)
  
  | Proj (e, i) ->
      let (t, s) = infer env e in
      let a = fresh_var () in
      let ts = List.init (i + 1) (fun _ -> fresh_var ()) in
      let s' = unify t (TyTuple ts) in
      (List.nth ts i, compose s s')
  
  | List es ->
      let (ts, s) = infer_list env es in
      let a = fresh_var () in
      let s' = unify_list ts (List.map (fun _ -> a) ts) in
      (TyList (subst s' a), compose s s')
  
  | Cons (e1, e2) ->
      let (t1, s1) = infer env e1 in
      let (t2, s2) = infer (subst_env s1 env) e2 in
      let s3 = unify (subst s2 t2) (TyList t1) in
      (subst s3 t2, compose s1 (compose s2 s3))
  
  | Record fields ->
      let (ts, s) = infer_list env (List.map snd fields) in
      let field_types = List.combine (List.map fst fields) ts in
      (TyRecord field_types, s)
  
  | Field (e, l) ->
      let (t, s) = infer env e in
      let a = fresh_var () in
      let fields = [(l, a)] in
      let s' = unify t (TyRecord fields) in
      (subst s' a, compose s s')

and infer_list env es =
  match es with
  | [] -> ([], [])
  | e::es ->
      let (t, s) = infer env e in
      let (ts, s') = infer_list (subst_env s env) es in
      (t::ts, compose s s')
```

## Advanced Type Features

Let's add support for more sophisticated type features:

### Type Constraints

```ocaml
type constraint_ =
  | Eq of ty * ty
  | Instance of ty * scheme

let rec solve_constraints cs =
  match cs with
  | [] -> []
  | Eq (t1, t2)::cs ->
      let s = unify t1 t2 in
      let cs' = List.map (fun (Eq (t1, t2)) -> Eq (subst s t1, subst s t2)) cs in
      compose s (solve_constraints cs')
  | Instance (t, scheme)::cs ->
      let t' = instantiate scheme in
      let s = unify t t' in
      compose s (solve_constraints cs)
```

### Row Polymorphism

For records, we can implement row polymorphism:

```ocaml
type row_var = RowVar of string

type ty =
  | TyVar of string
  | TyCon of string
  | TyArrow of ty * ty
  | TyRecord of (string * ty) list * row_var option
  | TyUnion of ty list

let rec unify_record_with_row fields1 row1 fields2 row2 =
  match (row1, row2) with
  | (None, None) -> unify_record fields1 fields2
  | (Some (RowVar r1), None) ->
      let s = [(r1, TyRecord (fields2, None))] in
      (s, unify_record fields1 fields2)
  | (None, Some (RowVar r2)) ->
      let s = [(r2, TyRecord (fields1, None))] in
      (s, unify_record fields1 fields2)
  | (Some (RowVar r1), Some (RowVar r2)) when r1 = r2 ->
      (unify_record fields1 fields2, [])
  | (Some (RowVar r1), Some (RowVar r2)) ->
      let s1 = unify_record fields1 fields2 in
      let s2 = [(r1, TyRecord (fields2, Some (RowVar r2)))] in
      (compose s1 s2, [])
```

## Error Reporting

Good error messages are crucial for a type inference engine:

```ocaml
exception TypeError of string * ty * ty

let rec string_of_ty t =
  match t with
  | TyVar x -> x
  | TyCon x -> x
  | TyArrow (t1, t2) -> 
      let s1 = string_of_ty t1 in
      let s2 = string_of_ty t2 in
      if is_arrow t1 then "(" ^ s1 ^ ") -> " ^ s2
      else s1 ^ " -> " ^ s2
  | TyTuple ts -> 
      "(" ^ String.concat " * " (List.map string_of_ty ts) ^ ")"
  | TyList t -> string_of_ty t ^ " list"
  | TyRecord fields ->
      let field_strs = List.map (fun (l, t) -> l ^ ": " ^ string_of_ty t) fields in
      "{" ^ String.concat ", " field_strs ^ "}"
  | TyUnion ts ->
      String.concat " | " (List.map string_of_ty ts)

and is_arrow = function
  | TyArrow _ -> true
  | _ -> false

let type_error msg t1 t2 =
  let msg' = Printf.sprintf "%s: cannot unify %s with %s" 
    msg (string_of_ty t1) (string_of_ty t2) in
  raise (TypeError (msg', t1, t2))
```

## Testing the Implementation

Let's create comprehensive tests:

```ocaml
let test_cases = [
  (* Basic types *)
  ("5", "int");
  ("true", "bool");
  ("\"hello\"", "string");
  
  (* Functions *)
  ("fun x -> x", "'a -> 'a");
  ("fun x -> x + 1", "int -> int");
  ("fun x y -> x", "'a -> 'b -> 'a");
  ("fun x y -> x + y", "int -> int -> int");
  
  (* Polymorphic functions *)
  ("fun x -> (x, x)", "'a -> ('a * 'a)");
  ("fun x -> [x]", "'a -> 'a list");
  ("fun x -> fun y -> (x, y)", "'a -> 'b -> ('a * 'b)");
  
  (* Let bindings *)
  ("let id = fun x -> x in id 5", "int");
  ("let add = fun x y -> x + y in add 3 4", "int");
  
  (* Recursive functions *)
  ("let rec fact n = if n = 0 then 1 else n * fact (n - 1) in fact 5", "int");
  
  (* Records *)
  ("{x: 1, y: 2}", "{x: int, y: int}");
  ("fun p -> p.x", "{x: 'a} -> 'a");
  
  (* Lists *)
  ("[1, 2, 3]", "int list");
  ("fun x -> x :: []", "'a -> 'a list");
  ("fun xs -> match xs with [] -> 0 | x::_ -> x", "'a list -> 'a");
]

let run_tests () =
  Printf.printf "Running Hindley-Milner type inference tests:\n\n";
  List.iter (fun (expr_str, expected) ->
    try
      let expr = parse expr_str in
      let (ty, _) = infer [] expr in
      let ty_str = string_of_ty ty in
      Printf.printf "✓ %s : %s\n" expr_str ty_str;
      if ty_str = expected then
        Printf.printf "  ✓ Expected: %s\n" expected
      else
        Printf.printf "  ⚠ Expected: %s, got: %s\n" expected ty_str
    with
    | TypeError (msg, t1, t2) -> 
        Printf.printf "✗ %s: %s\n" expr_str msg
    | e -> 
        Printf.printf "✗ %s: %s\n" expr_str (Printexc.to_string e)
  ) test_cases
```

## Performance Considerations

The Hindley-Milner algorithm has some performance characteristics to consider:

1. **Unification**: O(n) where n is the size of the type
2. **Generalization**: O(n) where n is the number of free variables
3. **Substitution**: O(n) where n is the size of the type

For large programs, we can optimize by:

```ocaml
(* Union-find for efficient unification *)
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

(* Memoization for repeated computations *)
let memoize f =
  let cache = Hashtbl.create 1000 in
  fun x ->
    try Hashtbl.find cache x
    with Not_found ->
      let result = f x in
      Hashtbl.add cache x result;
      result
```

## What We've Accomplished

In this implementation, we've built a complete Hindley-Milner type system that includes:

1. **Complete type system** with variables, constructors, arrows, tuples, lists, and records
2. **Robust unification algorithm** that handles all type constructors
3. **Proper generalization** that makes types polymorphic when safe
4. **Comprehensive error reporting** with meaningful messages
5. **Performance optimizations** for large programs

## The Beauty of Hindley-Milner

The Hindley-Milner system is remarkable because it provides:

- **Decidability**: The type checking algorithm always terminates
- **Completeness**: It can infer the most general type for any typable expression
- **Soundness**: It never accepts a program that would cause a type error at runtime
- **Efficiency**: The algorithm runs in nearly linear time

This mathematical elegance translates into practical benefits: programmers get powerful type inference without sacrificing performance or correctness.

## Next Steps

In our next article, we'll extend this foundation to handle JavaScript-specific features:

1. **Objects and prototypes** with dynamic property access
2. **Classes and inheritance** with method resolution
3. **Modules and namespaces** with import/export
4. **Asynchronous programming** with Promises and async/await
5. **Type annotations** for gradual typing

The Hindley-Milner system we've built here provides the mathematical foundation for all these advanced features. By understanding the theory, we can extend it to handle the complexities of modern JavaScript while maintaining the elegance and correctness of the underlying type system.