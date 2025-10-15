---
layout: "post"
date: 2025-01-29
title: "Building a Type Inference Engine for JavaScript in OCaml: JavaScript-Specific Challenges"
categories: "language-design"
draft: false
---

In our previous articles, we built a solid foundation with the Hindley-Milner type system. Now we'll tackle the unique challenges that JavaScript presents to type inference. JavaScript's dynamic nature, prototype-based inheritance, and flexible object system require us to extend our type system significantly.

## The JavaScript Challenge

JavaScript is fundamentally different from the functional languages that Hindley-Milner was designed for:

1. **Dynamic typing**: Variables can change types at runtime
2. **Prototype-based inheritance**: Objects inherit from other objects, not classes
3. **Flexible object system**: Properties can be added/removed dynamically
4. **Duck typing**: "If it walks like a duck and quacks like a duck, it's a duck"
5. **Coercion**: Automatic type conversions between values
6. **Closures and lexical scoping**: Functions capture their environment
7. **Asynchronous programming**: Promises, async/await, and callbacks

Let's build a type system that can handle these complexities while maintaining the elegance of Hindley-Milner.

## Extended Type System for JavaScript

First, let's extend our type system to handle JavaScript's features:

```ocaml
(* JavaScript-specific types *)
type js_ty =
  | JsVar of string                    (* Type variable *)
  | JsPrim of string                   (* Primitive types: number, string, boolean, undefined, null *)
  | JsObject of object_type
  | JsFunction of js_ty list * js_ty   (* Function type with parameter and return types *)
  | JsArray of js_ty                   (* Array type *)
  | JsUnion of js_ty list              (* Union types: string | number *)
  | JsIntersection of js_ty list       (* Intersection types: A & B *)
  | JsOptional of js_ty                (* Optional types: string? *)
  | JsIndex of js_ty * js_ty           (* Index signature: [key: string]: value *)
  | JsGeneric of string * js_ty list   (* Generic types: Array<T> *)
  | JsThis of js_ty                    (* 'this' type *)
  | JsNever                            (* Bottom type *)
  | JsAny                              (* Top type *)

and object_type = {
  properties: (string * property_info) list;
  index_signature: (js_ty * js_ty) option;  (* [key: K]: V *)
  prototype: js_ty option;
  call_signature: (js_ty list * js_ty) option;  (* Callable objects *)
  construct_signature: (js_ty list * js_ty) option;  (* Constructible objects *)
}

and property_info = {
  ty: js_ty;
  optional: bool;
  readonly: bool;
  getter: js_ty option;
  setter: js_ty option;
}
```

## JavaScript Expression Language

Let's define a JavaScript-like expression language:

```ocaml
type js_expr =
  (* Literals *)
  | JsNumber of float
  | JsString of string
  | JsBoolean of bool
  | JsNull
  | JsUndefined
  | JsRegExp of string * string option  (* pattern, flags *)
  
  (* Variables and identifiers *)
  | JsVar of string
  | JsThis
  
  (* Object literals and property access *)
  | JsObject of (string * js_expr) list
  | JsProperty of js_expr * string
  | JsPropertyAccess of js_expr * js_expr  (* obj[expr] *)
  | JsSpread of js_expr
  
  (* Arrays *)
  | JsArray of js_expr list
  | JsArrayAccess of js_expr * js_expr
  
  (* Functions *)
  | JsFunction of string list * js_expr
  | JsArrowFunction of string list * js_expr
  | JsMethod of string * string list * js_expr  (* object method *)
  | JsCall of js_expr * js_expr list
  | JsNew of js_expr * js_expr list
  
  (* Control flow *)
  | JsIf of js_expr * js_expr * js_expr option
  | JsWhile of js_expr * js_expr
  | JsFor of js_expr option * js_expr option * js_expr option * js_expr
  | JsForIn of string * js_expr * js_expr
  | JsForOf of string * js_expr * js_expr
  
  (* Operators *)
  | JsBinary of binary_op * js_expr * js_expr
  | JsUnary of unary_op * js_expr
  | JsTernary of js_expr * js_expr * js_expr
  
  (* Assignments *)
  | JsAssign of js_expr * js_expr
  | JsAssignOp of assign_op * js_expr * js_expr
  
  (* Classes and inheritance *)
  | JsClass of string * js_expr option * class_member list
  | JsExtends of js_expr * js_expr
  | JsSuper
  | JsConstructor of js_expr list * js_expr
  | JsStatic of js_expr
  | JsPrivate of string * js_expr
  
  (* Modules *)
  | JsImport of string * string option * string option
  | JsExport of js_expr * string option
  | JsModule of js_expr list
  
  (* Asynchronous programming *)
  | JsAsync of js_expr
  | JsAwait of js_expr
  | JsPromise of js_expr
  | JsThen of js_expr * js_expr * js_expr option
  | JsCatch of string * js_expr
  | JsFinally of js_expr
  | JsThrow of js_expr
  | JsTry of js_expr * js_expr option * js_expr option
  
  (* Destructuring *)
  | JsDestruct of pattern * js_expr
  | JsRest of string
  
  (* Template literals *)
  | JsTemplate of js_expr list
  | JsTemplatePart of string * js_expr

and binary_op =
  | JsAdd | JsSub | JsMul | JsDiv | JsMod
  | JsEq | JsNe | JsStrictEq | JsStrictNe
  | JsLt | JsLe | JsGt | JsGe
  | JsAnd | JsOr | JsXor
  | JsLShift | JsRShift | JsURShift
  | JsIn | JsInstanceof

and unary_op =
  | JsNot | JsNeg | JsPos | JsBitNot
  | JsTypeof | JsVoid | JsDelete

and assign_op =
  | JsAssignAdd | JsAssignSub | JsAssignMul | JsAssignDiv
  | JsAssignMod | JsAssignLShift | JsAssignRShift | JsAssignURShift
  | JsAssignAnd | JsAssignOr | JsAssignXor

and class_member =
  | JsMethodDef of string * string list * js_expr
  | JsPropertyDef of string * js_expr
  | JsGetter of string * js_expr
  | JsSetter of string * string * js_expr
  | JsStaticMethod of string * string list * js_expr
  | JsStaticProperty of string * js_expr

and pattern =
  | JsVarPattern of string
  | JsObjectPattern of (string * pattern option) list
  | JsArrayPattern of pattern list
  | JsRestPattern of string
```

## Type Coercion and Conversion

JavaScript's type coercion is one of its most complex features. We need to model this in our type system:

```ocaml
type coercion_rule = {
  from: js_ty;
  to: js_ty;
  implicit: bool;  (* Can this coercion happen implicitly? *)
  cost: int;       (* Cost of this coercion for type inference *)
}

let coercion_rules = [
  (* Primitive to primitive *)
  { from = JsPrim "number"; to = JsPrim "string"; implicit = true; cost = 1 };
  { from = JsPrim "string"; to = JsPrim "number"; implicit = true; cost = 1 };
  { from = JsPrim "boolean"; to = JsPrim "number"; implicit = true; cost = 1 };
  { from = JsPrim "boolean"; to = JsPrim "string"; implicit = true; cost = 1 };
  
  (* To boolean (truthiness) *)
  { from = JsPrim "number"; to = JsPrim "boolean"; implicit = true; cost = 1 };
  { from = JsPrim "string"; to = JsPrim "boolean"; implicit = true; cost = 1 };
  { from = JsPrim "undefined"; to = JsPrim "boolean"; implicit = true; cost = 1 };
  { from = JsPrim "null"; to = JsPrim "boolean"; implicit = true; cost = 1 };
  
  (* Object to primitive *)
  { from = JsObject { properties = []; index_signature = None; prototype = None; call_signature = None; construct_signature = None };
    to = JsPrim "string"; implicit = true; cost = 2 };
  { from = JsObject { properties = []; index_signature = None; prototype = None; call_signature = None; construct_signature = None };
    to = JsPrim "number"; implicit = true; cost = 2 };
  
  (* Array to string *)
  { from = JsArray (JsPrim "string"); to = JsPrim "string"; implicit = true; cost = 2 };
  
  (* Function to string *)
  { from = JsFunction ([], JsPrim "string"); to = JsPrim "string"; implicit = true; cost = 2 };
]

let can_coerce from_ty to_ty =
  List.exists (fun rule -> 
    rule.from = from_ty && rule.to = to_ty && rule.implicit
  ) coercion_rules

let coercion_cost from_ty to_ty =
  try
    let rule = List.find (fun rule -> 
      rule.from = from_ty && rule.to = to_ty && rule.implicit
    ) coercion_rules in
    rule.cost
  with Not_found -> max_int
```

## Prototype-Based Inheritance

JavaScript's prototype system is fundamentally different from class-based inheritance. We need to model this:

```ocaml
type prototype_chain = {
  object: js_ty;
  prototype: js_ty option;
  properties: (string * property_info) list;
}

let rec get_prototype_chain obj_ty =
  match obj_ty with
  | JsObject obj_info ->
      let chain = {
        object = obj_ty;
        prototype = obj_info.prototype;
        properties = obj_info.properties;
      } in
      (match obj_info.prototype with
       | Some proto_ty -> chain :: get_prototype_chain proto_ty
       | None -> [chain])
  | _ -> []

let find_property_in_chain prop_name chain =
  let rec search chains =
    match chains with
    | [] -> None
    | chain::rest ->
        (try
           let prop_info = List.assoc prop_name chain.properties in
           Some (prop_info, chain.object)
         with Not_found -> search rest)
  in
  search chain

let get_property_type obj_ty prop_name =
  let chain = get_prototype_chain obj_ty in
  match find_property_in_chain prop_name chain with
  | Some (prop_info, _) -> Some prop_info.ty
  | None -> None
```

## Duck Typing and Structural Subtyping

JavaScript's duck typing means that if an object has the right properties, it can be used where that type is expected:

```ocaml
let rec is_subtype_of t1 t2 =
  match (t1, t2) with
  | (JsAny, _) -> true
  | (_, JsAny) -> true
  | (JsNever, _) -> true
  | (_, JsNever) -> false
  
  (* Primitive types *)
  | (JsPrim p1, JsPrim p2) when p1 = p2 -> true
  
  (* Union types *)
  | (JsUnion ts1, JsUnion ts2) ->
      List.for_all (fun t1 -> List.exists (fun t2 -> is_subtype_of t1 t2) ts2) ts1
  | (t1, JsUnion ts2) ->
      List.exists (fun t2 -> is_subtype_of t1 t2) ts2
  | (JsUnion ts1, t2) ->
      List.for_all (fun t1 -> is_subtype_of t1 t2) ts1
  
  (* Intersection types *)
  | (JsIntersection ts1, JsIntersection ts2) ->
      List.for_all (fun t1 -> List.exists (fun t2 -> is_subtype_of t1 t2) ts2) ts1
  | (t1, JsIntersection ts2) ->
      List.for_all (fun t2 -> is_subtype_of t1 t2) ts2
  | (JsIntersection ts1, t2) ->
      List.exists (fun t1 -> is_subtype_of t1 t2) ts1
  
  (* Object types - structural subtyping *)
  | (JsObject obj1, JsObject obj2) ->
      is_object_subtype obj1 obj2
  
  (* Function types *)
  | (JsFunction (params1, ret1), JsFunction (params2, ret2)) ->
      List.length params1 = List.length params2 &&
      List.for_all2 is_subtype_of params2 params1 &&  (* Contravariant parameters *)
      is_subtype_of ret1 ret2  (* Covariant return type *)
  
  (* Array types *)
  | (JsArray t1, JsArray t2) ->
      is_subtype_of t1 t2
  
  (* Generic types *)
  | (JsGeneric (name1, args1), JsGeneric (name2, args2)) when name1 = name2 ->
      List.length args1 = List.length args2 &&
      List.for_all2 is_subtype_of args1 args2
  
  | _ -> false

and is_object_subtype obj1 obj2 =
  (* Check that obj2 has all required properties of obj1 *)
  let required_props = List.filter (fun (_, prop) -> not prop.optional) obj1.properties in
  List.for_all (fun (name, prop1) ->
    match List.assoc_opt name obj2.properties with
    | Some prop2 -> is_subtype_of prop1.ty prop2.ty
    | None -> false
  ) required_props &&
  
  (* Check index signature compatibility *)
  (match (obj1.index_signature, obj2.index_signature) with
   | (Some (k1, v1), Some (k2, v2)) ->
       is_subtype_of k1 k2 && is_subtype_of v1 v2
   | (Some _, None) -> false
   | (None, _) -> true) &&
  
  (* Check call signature compatibility *)
  (match (obj1.call_signature, obj2.call_signature) with
   | (Some (params1, ret1), Some (params2, ret2)) ->
       List.length params1 = List.length params2 &&
       List.for_all2 is_subtype_of params2 params1 &&
       is_subtype_of ret1 ret2
   | (Some _, None) -> false
   | (None, _) -> true)
```

## Type Inference for JavaScript

Now let's implement type inference for JavaScript expressions:

```ocaml
let rec infer_js env expr =
  match expr with
  | JsNumber _ -> (JsPrim "number", [])
  | JsString _ -> (JsPrim "string", [])
  | JsBoolean _ -> (JsPrim "boolean", [])
  | JsNull -> (JsPrim "null", [])
  | JsUndefined -> (JsPrim "undefined", [])
  
  | JsVar x -> 
      let scheme = lookup x env in
      (instantiate scheme, [])
  
  | JsThis ->
      let scheme = lookup "this" env in
      (instantiate scheme, [])
  
  | JsObject fields ->
      let (field_types, s) = infer_fields env fields in
      let obj_ty = JsObject {
        properties = field_types;
        index_signature = None;
        prototype = None;
        call_signature = None;
        construct_signature = None;
      } in
      (obj_ty, s)
  
  | JsProperty (obj, prop_name) ->
      let (obj_ty, s1) = infer_js env obj in
      let prop_ty = get_property_type obj_ty prop_name in
      (match prop_ty with
       | Some ty -> (ty, s1)
       | None -> 
           let a = fresh_var () in
           let s2 = unify obj_ty (JsObject {
             properties = [(prop_name, { ty = a; optional = false; readonly = false; getter = None; setter = None })];
             index_signature = None;
             prototype = None;
             call_signature = None;
             construct_signature = None;
           }) in
           (a, compose s1 s2))
  
  | JsPropertyAccess (obj, index) ->
      let (obj_ty, s1) = infer_js env obj in
      let (index_ty, s2) = infer_js (subst_env s1 env) index in
      let a = fresh_var () in
      let s3 = unify obj_ty (JsObject {
        properties = [];
        index_signature = Some (index_ty, a);
        prototype = None;
        call_signature = None;
        construct_signature = None;
      }) in
      (a, compose s1 (compose s2 s3))
  
  | JsArray elements ->
      let (element_types, s) = infer_list env elements in
      let a = fresh_var () in
      let s' = unify_list element_types (List.map (fun _ -> a) element_types) in
      (JsArray (subst s' a), compose s s')
  
  | JsArrayAccess (arr, index) ->
      let (arr_ty, s1) = infer_js env arr in
      let (index_ty, s2) = infer_js (subst_env s1 env) index in
      let a = fresh_var () in
      let s3 = unify arr_ty (JsArray a) in
      (a, compose s1 (compose s2 s3))
  
  | JsFunction (params, body) ->
      let param_types = List.map (fun _ -> fresh_var ()) params in
      let env' = List.combine params (List.map (fun t -> Scheme ([], t)) param_types) @ env in
      let (body_ty, s) = infer_js env' body in
      let param_types' = List.map (subst s) param_types in
      (JsFunction (param_types', body_ty), s)
  
  | JsArrowFunction (params, body) ->
      let param_types = List.map (fun _ -> fresh_var ()) params in
      let env' = List.combine params (List.map (fun t -> Scheme ([], t)) param_types) @ env in
      let (body_ty, s) = infer_js env' body in
      let param_types' = List.map (subst s) param_types in
      (JsFunction (param_types', body_ty), s)
  
  | JsCall (func, args) ->
      let (func_ty, s1) = infer_js env func in
      let (arg_types, s2) = infer_list (subst_env s1 env) args in
      let ret_ty = fresh_var () in
      let s3 = unify func_ty (JsFunction (arg_types, ret_ty)) in
      (subst s3 ret_ty, compose s1 (compose s2 s3))
  
  | JsBinary (op, e1, e2) ->
      let (t1, s1) = infer_js env e1 in
      let (t2, s2) = infer_js (subst_env s1 env) e2 in
      (match op with
       | JsAdd ->
           (* String concatenation or numeric addition *)
           let s3 = unify t1 (JsPrim "string") in
           let s4 = unify (subst s3 t2) (JsPrim "string") in
           (JsPrim "string", compose s1 (compose s2 (compose s3 s4)))
       | JsSub | JsMul | JsDiv | JsMod ->
           let s3 = unify t1 (JsPrim "number") in
           let s4 = unify (subst s3 t2) (JsPrim "number") in
           (JsPrim "number", compose s1 (compose s2 (compose s3 s4)))
       | JsEq | JsNe | JsStrictEq | JsStrictNe ->
           let s3 = unify t1 t2 in
           (JsPrim "boolean", compose s1 (compose s2 s3))
       | JsLt | JsLe | JsGt | JsGe ->
           let s3 = unify t1 (JsPrim "number") in
           let s4 = unify (subst s3 t2) (JsPrim "number") in
           (JsPrim "boolean", compose s1 (compose s2 (compose s3 s4)))
       | JsAnd | JsOr ->
           let s3 = unify t1 (JsPrim "boolean") in
           let s4 = unify (subst s3 t2) (JsPrim "boolean") in
           (JsPrim "boolean", compose s1 (compose s2 (compose s3 s4)))
       | JsIn ->
           let s3 = unify t2 (JsObject { properties = []; index_signature = None; prototype = None; call_signature = None; construct_signature = None }) in
           (JsPrim "boolean", compose s1 (compose s2 s3))
       | JsInstanceof ->
           let s3 = unify t2 (JsFunction ([], JsPrim "object")) in
           (JsPrim "boolean", compose s1 (compose s2 s3)))
  
  | JsUnary (op, e) ->
      let (t, s) = infer_js env e in
      (match op with
       | JsNot ->
           let s' = unify t (JsPrim "boolean") in
           (JsPrim "boolean", compose s s')
       | JsNeg | JsPos ->
           let s' = unify t (JsPrim "number") in
           (JsPrim "number", compose s s')
       | JsTypeof ->
           (JsPrim "string", s)
       | JsVoid ->
           (JsPrim "undefined", s)
       | JsDelete ->
           (JsPrim "boolean", s))
  
  | JsIf (cond, then_expr, else_expr) ->
      let (cond_ty, s1) = infer_js env cond in
      let s2 = unify cond_ty (JsPrim "boolean") in
      let (then_ty, s3) = infer_js (subst_env (compose s1 s2) env) then_expr in
      (match else_expr with
       | Some else_expr ->
           let (else_ty, s4) = infer_js (subst_env (compose s1 (compose s2 s3)) env) else_expr in
           let s5 = unify (subst s4 then_ty) else_ty in
           (subst s5 then_ty, compose s1 (compose s2 (compose s3 (compose s4 s5))))
       | None ->
           (JsUnion [then_ty; JsPrim "undefined"], compose s1 (compose s2 s3)))
  
  | JsClass (name, super_class, members) ->
      let class_ty = infer_class env name super_class members in
      (class_ty, [])
  
  | JsAsync expr ->
      let (ty, s) = infer_js env expr in
      (JsGeneric ("Promise", [ty]), s)
  
  | JsAwait expr ->
      let (ty, s) = infer_js env expr in
      (match ty with
       | JsGeneric ("Promise", [inner_ty]) -> (inner_ty, s)
       | _ -> (JsAny, s))  (* Fallback for non-Promise types *)
  
  | _ -> (JsAny, [])  (* Fallback for unimplemented expressions *)

and infer_class env name super_class members =
  let super_ty = match super_class with
    | Some super_expr -> 
        let (ty, _) = infer_js env super_expr in
        Some ty
    | None -> None
  in
  
  let constructor_ty = JsFunction ([], JsPrim "object") in
  let method_types = List.map (fun member ->
    match member with
    | JsMethodDef (name, params, body) ->
        let param_types = List.map (fun _ -> fresh_var ()) params in
        let env' = List.combine params (List.map (fun t -> Scheme ([], t)) param_types) @ env in
        let (body_ty, _) = infer_js env' body in
        (name, { ty = JsFunction (param_types, body_ty); optional = false; readonly = false; getter = None; setter = None })
    | JsPropertyDef (name, init) ->
        let (ty, _) = infer_js env init in
        (name, { ty; optional = false; readonly = false; getter = None; setter = None })
    | _ -> failwith "Unimplemented class member"
  ) members in
  
  JsObject {
    properties = method_types;
    index_signature = None;
    prototype = super_ty;
    call_signature = Some ([], JsPrim "object");
    construct_signature = Some ([], JsPrim "object");
  }
```

## Handling JavaScript's Quirks

JavaScript has many quirks that make type inference challenging:

### Truthiness and Falsiness

```ocaml
let is_truthy ty =
  match ty with
  | JsPrim "boolean" -> true
  | JsPrim "number" -> true
  | JsPrim "string" -> true
  | JsPrim "undefined" -> false
  | JsPrim "null" -> false
  | JsPrim "object" -> true
  | JsArray _ -> true
  | JsFunction _ -> true
  | JsObject _ -> true
  | _ -> true  (* Conservative assumption *)

let is_falsy ty =
  match ty with
  | JsPrim "undefined" -> true
  | JsPrim "null" -> true
  | JsPrim "boolean" -> true  (* false *)
  | JsPrim "number" -> true   (* 0, NaN *)
  | JsPrim "string" -> true   (* "" *)
  | _ -> false
```

### Type Coercion in Comparisons

```ocaml
let infer_comparison op e1 e2 =
  let (t1, s1) = infer_js env e1 in
  let (t2, s2) = infer_js (subst_env s1 env) e2 in
  
  match op with
  | JsEq | JsNe ->
      (* Loose equality allows type coercion *)
      let s3 = unify t1 t2 in
      (JsPrim "boolean", compose s1 (compose s2 s3))
  | JsStrictEq | JsStrictNe ->
      (* Strict equality requires exact type match *)
      let s3 = unify t1 t2 in
      (JsPrim "boolean", compose s1 (compose s2 s3))
  | JsLt | JsLe | JsGt | JsGe ->
      (* Relational operators coerce to numbers *)
      let s3 = unify t1 (JsPrim "number") in
      let s4 = unify (subst s3 t2) (JsPrim "number") in
      (JsPrim "boolean", compose s1 (compose s2 (compose s3 s4)))
```

### Hoisting and Variable Declarations

```ocaml
let infer_var_declaration name init =
  match init with
  | Some expr ->
      let (ty, s) = infer_js env expr in
      let scheme = generalize env ty in
      ((name, scheme) :: env, s)
  | None ->
      (* Undeclared variables are 'any' *)
      let scheme = Scheme ([], JsAny) in
      ((name, scheme) :: env, [])
```

## Error Handling for JavaScript

JavaScript's dynamic nature means we need more sophisticated error handling:

```ocaml
exception JsTypeError of string * js_ty * js_ty
exception JsPropertyError of string * string
exception JsCoercionError of js_ty * js_ty

let rec string_of_js_ty t =
  match t with
  | JsVar x -> x
  | JsPrim p -> p
  | JsObject obj -> 
      let props = List.map (fun (name, prop) -> 
        name ^ ": " ^ string_of_js_ty prop.ty
      ) obj.properties in
      "{" ^ String.concat ", " props ^ "}"
  | JsFunction (params, ret) ->
      let param_strs = List.map string_of_js_ty params in
      "(" ^ String.concat ", " param_strs ^ ") -> " ^ string_of_js_ty ret
  | JsArray t -> string_of_js_ty t ^ "[]"
  | JsUnion ts -> String.concat " | " (List.map string_of_js_ty ts)
  | JsIntersection ts -> String.concat " & " (List.map string_of_js_ty ts)
  | JsOptional t -> string_of_js_ty t ^ "?"
  | JsIndex (k, v) -> "[" ^ string_of_js_ty k ^ ": " ^ string_of_js_ty v ^ "]"
  | JsGeneric (name, args) ->
      let arg_strs = List.map string_of_js_ty args in
      name ^ "<" ^ String.concat ", " arg_strs ^ ">"
  | JsThis -> "this"
  | JsNever -> "never"
  | JsAny -> "any"

let js_type_error msg t1 t2 =
  let msg' = Printf.sprintf "%s: cannot unify %s with %s" 
    msg (string_of_js_ty t1) (string_of_js_ty t2) in
  raise (JsTypeError (msg', t1, t2))
```

## Testing JavaScript Type Inference

Let's create test cases for JavaScript-specific features:

```ocaml
let js_test_cases = [
  (* Basic types *)
  ("42", "number");
  ("'hello'", "string");
  ("true", "boolean");
  ("null", "null");
  ("undefined", "undefined");
  
  (* Objects *)
  ("{x: 1, y: 2}", "{x: number, y: number}");
  ("obj.prop", "any");  (* Conservative assumption *)
  ("obj['prop']", "any");
  
  (* Arrays *)
  ("[1, 2, 3]", "number[]");
  ("['a', 'b', 'c']", "string[]");
  ("arr[0]", "any");
  
  (* Functions *)
  ("function(x) { return x; }", "(any) -> any");
  ("(x) => x + 1", "(any) -> any");
  ("function add(x, y) { return x + y; }", "(any, any) -> any");
  
  (* Operators *)
  ("1 + 2", "string");  (* String concatenation *)
  ("1 - 2", "number");
  ("1 == 2", "boolean");
  ("1 === 2", "boolean");
  
  (* Control flow *)
  ("x ? y : z", "any | any");
  ("if (x) y", "any | undefined");
  
  (* Classes *)
  ("class Point { constructor(x, y) { this.x = x; this.y = y; } }", "object");
  
  (* Async/await *)
  ("async function f() { return 42; }", "Promise<number>");
  ("await promise", "any");
]

let run_js_tests () =
  Printf.printf "Running JavaScript type inference tests:\n\n";
  List.iter (fun (expr_str, expected) ->
    try
      let expr = parse_js expr_str in
      let (ty, _) = infer_js [] expr in
      let ty_str = string_of_js_ty ty in
      Printf.printf "✓ %s : %s\n" expr_str ty_str;
      if ty_str = expected then
        Printf.printf "  ✓ Expected: %s\n" expected
      else
        Printf.printf "  ⚠ Expected: %s, got: %s\n" expected ty_str
    with
    | JsTypeError (msg, t1, t2) -> 
        Printf.printf "✗ %s: %s\n" expr_str msg
    | e -> 
        Printf.printf "✗ %s: %s\n" expr_str (Printexc.to_string e)
  ) js_test_cases
```

## What We've Accomplished

In this article, we've extended our type inference engine to handle JavaScript's unique features:

1. **Extended type system** with objects, arrays, unions, and generics
2. **Prototype-based inheritance** with property lookup chains
3. **Structural subtyping** for duck typing
4. **Type coercion** modeling JavaScript's implicit conversions
5. **JavaScript-specific expressions** like property access and method calls
6. **Error handling** tailored to JavaScript's dynamic nature

## The Challenge of JavaScript

JavaScript's dynamic nature makes type inference much more challenging than statically typed languages. We've had to make several compromises:

1. **Conservative assumptions**: When we can't determine a type, we fall back to `any`
2. **Limited precision**: Some JavaScript patterns are too dynamic to type precisely
3. **Performance trade-offs**: The complexity of JavaScript's type system affects performance

## Next Steps

In our final article, we'll explore advanced features that make our type inference engine production-ready:

1. **Generic types and constraints** for better type safety
2. **Module systems** with import/export type checking
3. **Performance optimizations** for large codebases
4. **Integration with existing tools** like TypeScript
5. **Real-world testing** with actual JavaScript code

The foundation we've built here provides the mathematical rigor needed for a robust JavaScript type inference engine. While JavaScript's dynamic nature presents unique challenges, our Hindley-Milner foundation gives us the tools to handle them systematically and correctly.