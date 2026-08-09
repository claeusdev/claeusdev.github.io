---
layout: post
title: "Operational Semantics: Adding Variables, Functions and Conditionals"
description: "Extend a simple arithmetic language with variables, functions, and conditionals. Learn about environments, closures, and lexical scoping in operational semantics."
date: 2025-02-14
author: "Nana Adjei Manu"
category: "language-design"
tags: ["Programming Languages", "Semantics", "Lambda Calculus", "Functional Programming"]
math: true
---

In our previous article, we explored operational semantics using a simple language of arithmetic expressions. While instructive, a language with only arithmetic operations is quite limited. In this article, we'll extend our language with three powerful features: variables, functions, and conditionals. These additions transform our simple calculator into a complete functional programming language.

## Extending Our Language

Let's start by extending the syntax of our language:

```
e ::= n                       (Number literals)
    | x                       (Variables)
    | e + e                   (Addition)
    | e - e                   (Subtraction)
    | e * e                   (Multiplication)
    | e / e                   (Division)
    | if e then e else e      (Conditional)
    | λx.e                    (Function abstraction/Lambda)
    | e e                     (Function application)
```

Where:

- `n` represents integer constants
- `x` represents variable names
- `λx.e` defines a function with parameter `x` and body `e`
- `e e` applies the function in the first expression to the argument in the second
- `if e then e else e` evaluates the first expression and then evaluates either the second or third expression based on the result

### Values in Our Extended Language

With the addition of functions, we need to update what we consider "values" in our language:

```
v ::= n                       (Number literals)
    | λx.e                    (Function values)
```

A value is now either a number or a function abstraction. Both represent fully evaluated expressions that cannot be reduced further.

## Introducing Environments

To handle variables, we need a way to keep track of their bindings. This is done with environments. An environment (typically denoted ρ or Γ) maps variable names to their values:

```
ρ ::= ∅                       (Empty environment)
    | ρ[x ↦ v]                (Environment extended with a binding)
```

We use the notation ρ(x) to look up the value of variable x in environment ρ.

## Small-Step Operational Semantics with Environments

With environments, our small-step transition relation becomes `⟨e, ρ⟩ → ⟨e', ρ'⟩`, indicating that expression `e` in environment `ρ` reduces to expression `e'` in environment `ρ'`.

### Variable Lookup

$$
\langle x, \rho \rangle \to \langle v, \rho \rangle \qquad \text{where } \rho(x) = v
$$

This rule says: A variable reference evaluates to the value it's bound to in the current environment.

### Arithmetic Operations

The rules for arithmetic are similar to before, but now include the environment:

$$
\begin{aligned}
\langle n_1 + n_2, \rho \rangle &\to \langle n_3, \rho \rangle &&\text{where } n_3 = n_1 + n_2\\
\langle n_1 - n_2, \rho \rangle &\to \langle n_3, \rho \rangle &&\text{where } n_3 = n_1 - n_2\\
\langle n_1 \times n_2, \rho \rangle &\to \langle n_3, \rho \rangle &&\text{where } n_3 = n_1 \times n_2\\
\langle n_1 / n_2, \rho \rangle &\to \langle n_3, \rho \rangle &&\text{where } n_3 = n_1 / n_2,\ n_2 \neq 0
\end{aligned}
$$

### Evaluation Context Rules for Arithmetic

The context rules also include environments:

$$
\frac{\langle e_1, \rho \rangle \to \langle e_1', \rho \rangle}{\langle e_1 + e_2, \rho \rangle \to \langle e_1' + e_2, \rho \rangle}
$$

$$
\frac{\langle e_2, \rho \rangle \to \langle e_2', \rho \rangle}{\langle v_1 + e_2, \rho \rangle \to \langle v_1 + e_2', \rho \rangle}
$$

Similar rules apply for subtraction, multiplication, and division.

### Conditional Expressions

$$
\frac{\langle e_1, \rho \rangle \to \langle e_1', \rho \rangle}{\langle \text{if } e_1 \text{ then } e_2 \text{ else } e_3, \rho \rangle \to \langle \text{if } e_1' \text{ then } e_2 \text{ else } e_3, \rho \rangle}
$$

$$
\begin{aligned}
\langle \text{if } 0 \text{ then } e_2 \text{ else } e_3, \rho \rangle &\to \langle e_3, \rho \rangle &&\text{(false: 0)}\\
\langle \text{if } n \text{ then } e_2 \text{ else } e_3, \rho \rangle &\to \langle e_2, \rho \rangle &&\text{(true: } n \neq 0\text{)}
\end{aligned}
$$

These rules say:

1. If the condition can be reduced, reduce it first
2. If the condition is 0 (representing false), evaluate the else branch
3. If the condition is any non-zero number (representing true), evaluate the then branch

### Function Rules

A lambda expression (function) is already a value, so it doesn't reduce further:

$$
\langle \lambda x.e, \rho \rangle \to \langle \lambda x.e, \rho \rangle
$$

However, we need rules for function application:

$$
\frac{\langle e_1, \rho \rangle \to \langle e_1', \rho \rangle}{\langle e_1\, e_2, \rho \rangle \to \langle e_1'\, e_2, \rho \rangle}
\qquad
\frac{\langle e_2, \rho \rangle \to \langle e_2', \rho \rangle}{\langle v_1\, e_2, \rho \rangle \to \langle v_1\, e_2', \rho \rangle}
$$

$$
\langle (\lambda x.e)\, v, \rho \rangle \to \langle e, \rho[x \mapsto v] \rangle
$$

The first two rules are evaluation context rules that ensure we evaluate the function and argument expressions. The third rule is the crucial one for function application: when a function (λx.e) is applied to a value v, we evaluate the function body e in an environment extended with a binding from the parameter x to the argument value v.

### Example Derivation with a Function

Let's see how `(λx. x + 1) 5` evaluates:

```
⟨(λx. x + 1) 5, ρ⟩
→ ⟨x + 1, ρ[x ↦ 5]⟩     (function application)
→ ⟨5 + 1, ρ[x ↦ 5]⟩     (variable lookup)
→ ⟨6, ρ[x ↦ 5]⟩         (arithmetic operation)
```

This shows how:

1. The function is applied, creating a new environment where x is bound to 5
2. The variable x is looked up in this environment, yielding 5
3. The addition is performed, yielding the final result 6

### Example with Conditionals

Let's evaluate `if (3 - 3) then 10 else 20`:

```
⟨if (3 - 3) then 10 else 20, ρ⟩
→ ⟨if 0 then 10 else 20, ρ⟩     (evaluating the condition)
→ ⟨20, ρ⟩                       (condition is 0, so take else branch)
```

## Big-Step Operational Semantics with Environments

For big-step semantics with our extended language, our relation is `⟨e, ρ⟩ ⇓ v`, meaning expression e in environment ρ evaluates to value v.

### Constants and Variables

$$
\langle n, \rho \rangle \Downarrow n
\qquad\qquad
\langle x, \rho \rangle \Downarrow v \quad \text{where } \rho(x) = v
$$

### Arithmetic Operations

$$
\frac{\langle e_1, \rho \rangle \Downarrow n_1 \quad \langle e_2, \rho \rangle \Downarrow n_2}{\langle e_1 + e_2, \rho \rangle \Downarrow n_3}
\qquad (n_3 = n_1 + n_2)
$$

Similar rules apply for subtraction, multiplication, and division.

### Conditional Expressions

$$
\frac{\langle e_1, \rho \rangle \Downarrow 0 \quad \langle e_3, \rho \rangle \Downarrow v}{\langle \text{if } e_1 \text{ then } e_2 \text{ else } e_3, \rho \rangle \Downarrow v}
$$

$$
\frac{\langle e_1, \rho \rangle \Downarrow n \quad \langle e_2, \rho \rangle \Downarrow v \quad n \neq 0}{\langle \text{if } e_1 \text{ then } e_2 \text{ else } e_3, \rho \rangle \Downarrow v}
$$

### Functions

$$
\langle \lambda x.e, \rho \rangle \Downarrow \langle \lambda x.e, \rho \rangle
$$

In big-step semantics, a function evaluates to a closure, which captures both the function and its defining environment.

### Function Application

$$
\frac{\langle e_1, \rho \rangle \Downarrow \langle \lambda x.e, \rho' \rangle \quad \langle e_2, \rho \rangle \Downarrow v_2 \quad \langle e, \rho'[x \mapsto v_2] \rangle \Downarrow v}{\langle e_1\, e_2, \rho \rangle \Downarrow v}
$$

This rule says: To evaluate a function application e₁ e₂,

1. Evaluate e₁ to get a function closure ⟨λx.e, ρ'⟩
2. Evaluate e₂ to get the argument value v₂
3. Evaluate the function body e in the function's captured environment ρ' extended with a binding from parameter x to argument value v₂

### Example with Big-Step Semantics

Here's how we would derive the evaluation of `(λx. x + 1) 5` using big-step semantics:

$$
\frac{\langle \lambda x.\, x + 1, \rho \rangle \Downarrow \langle \lambda x.\, x + 1, \rho \rangle \quad \langle 5, \rho \rangle \Downarrow 5 \quad \langle x + 1, \rho[x \mapsto 5] \rangle \Downarrow 6}{\langle (\lambda x.\, x + 1)\, 5, \rho \rangle \Downarrow 6}
$$

Where `⟨x + 1, ρ[x ↦ 5]⟩ ⇓ 6` would be derived as:

$$
\frac{\langle x, \rho[x \mapsto 5] \rangle \Downarrow 5 \quad \langle 1, \rho[x \mapsto 5] \rangle \Downarrow 1}{\langle x + 1, \rho[x \mapsto 5] \rangle \Downarrow 6}
$$

## Lexical vs. Dynamic Scoping

The semantics we've defined uses lexical scoping (also called static scoping): a function captures the environment where it was defined. This is why our closures include both the function code and its environment.

To see the importance of this, consider:

```
let x = 1 in
let f = λy. x + y in
let x = 2 in
f 3
```

With lexical scoping, this evaluates to 4 (1 + 3) because f captures the environment where x is 1.

With dynamic scoping, it would evaluate to 5 (2 + 3) because x would be looked up in the calling environment.

Most modern languages use lexical scoping because it leads to more predictable behavior and supports better encapsulation.

## A More Complex Example: Higher-Order Functions

One of the powerful features of functional programming is higher-order functions—functions that take other functions as arguments or return them as results. Let's see how our semantics handles a simple higher-order function:

```
(λf. λx. f (f x)) (λy. y * 2) 3
```

This applies a function twice to an input. Let's trace through the evaluation:

```
⟨(λf. λx. f (f x)) (λy. y * 2) 3, ρ⟩
→ ⟨(λx. f (f x))[f ↦ (λy. y * 2)], 3, ρ⟩    (applying the first function)
→ ⟨f (f 3), ρ[f ↦ (λy. y * 2)][x ↦ 3]⟩     (applying the second function)
→ ⟨(λy. y * 2) ((λy. y * 2) 3), ρ[f ↦ (λy. y * 2)][x ↦ 3]⟩    (variable lookup)
→ ⟨(λy. y * 2) (3 * 2), ρ[f ↦ (λy. y * 2)][x ↦ 3]⟩    (applying inner function)
→ ⟨(λy. y * 2) 6, ρ[f ↦ (λy. y * 2)][x ↦ 3]⟩     (arithmetic)
→ ⟨6 * 2, ρ[f ↦ (λy. y * 2)][x ↦ 3][y ↦ 6]⟩     (applying outer function)
→ ⟨12, ρ[f ↦ (λy. y * 2)][x ↦ 3][y ↦ 6]⟩    (arithmetic)
```

This demonstrates how our semantics correctly handles the intricate behavior of higher-order functions.

## Adding Recursion

One crucial feature in functional programming is recursion. To add recursion to our language, we could introduce a special construct `rec f.e` that defines a recursive function:

```
e ::= ... | rec f.e   (Recursive function definition)
```

The semantics for this would involve a fixed-point operator, allowing the function to refer to itself.

Using this, we could define a factorial function:

```
rec fact. λn. if n then 1 else n * (fact (n - 1))
```

Applying this to 5 would compute 5!, or 120.

## Conclusion

By extending our language with variables, functions, and conditionals, we've created a small but complete functional programming language. The formal semantics we've defined provides a precise specification of how programs in this language execute, covering:

- Variable binding and lookup through environments
- Control flow through conditionals
- Abstraction through function definitions
- Computation through function application
- Lexical scoping and closures
- Higher-order functions

This framework forms the foundation of many real-world functional programming languages like Scheme, ML, Haskell, and even the functional aspects of JavaScript.

Further extensions to our language could include:

- Algebraic data types for structured data
- Pattern matching for data decomposition
- Mutable state for imperative features
- Exception handling for error management
- Module systems for code organization

Each of these would require additional semantic rules, but the fundamental approach would remain the same: precisely defining how programs execute, step by step.

Through operational semantics, we gain a rigorous understanding of programming language behavior, which guides language design, implementation, and verification—essential activities for building reliable and well-understood programming systems.
