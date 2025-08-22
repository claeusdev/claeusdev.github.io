---
layout: "post"
date: 2025-02-13
title: "Operational Semantics: A Formal Approach to Arithmetic Expressions"
categories: "language-design"
draft: false
---

Programming languages are precise, formal systems, yet we typically understand them through informal descriptions and examples. While this works for everyday programming, it falls short when designing languages, building compilers, or proving program correctness. This is where formal semantics comes in—particularly operational semantics, which provides a framework for describing how programs execute.

## What Is Operational Semantics?

Operational semantics is a formal method for describing how programs execute. It defines the meaning of a program by specifying the computational steps that occur when the program runs. Think of it as a mathematically precise specification of an interpreter for your language.

Unlike informal explanations that might say "this expression evaluates to that value," operational semantics provides explicit rules governing exactly *how* expressions transform into values through a series of state transitions.

## Why Formal Semantics Matters

You might wonder why we need such formality. Consider these benefits:

- **Precision**: Removes ambiguity from language specifications
- **Verification**: Enables mathematical proofs about program behavior
- **Compiler Correctness**: Provides a reference for validating compiler implementations
- **Language Design**: Helps detect inconsistencies or unexpected behaviors early

## Types of Operational Semantics

Operational semantics comes in two main flavors:

1. **Small-step semantics** (also called structural operational semantics): Describes program execution as a sequence of tiny, atomic steps
2. **Big-step semantics** (also called natural semantics): Describes how a program directly evaluates to its final result without showing intermediate steps

Let's explore both approaches using a simple language of arithmetic expressions.

## A Simple Arithmetic Language

To demonstrate operational semantics, we'll develop a tiny language for arithmetic expressions. Despite its simplicity, this example will showcase the essential concepts.

### Syntax of Our Language

First, we need to define what constitutes a valid program in our language. We'll use a standard technique called a grammar:

```
e ::= n               (Number literals)
    | e + e           (Addition)
    | e - e           (Subtraction)
    | e * e           (Multiplication)
    | e / e           (Division)
```

Where `n` represents integer constants, and `e` represents expressions. This grammar says that an expression can be either a number or the result of applying one of our arithmetic operations to two sub-expressions.

### Values in Our Language

In this simple language, our only values are numbers—expressions that cannot be reduced further:

```
v ::= n               (Number literals)
```

## Small-Step Operational Semantics

In small-step semantics, we define a transition relation `→` that shows how one expression reduces to another in a single computational step.

We write `e → e'` to indicate that expression `e` reduces to expression `e'` in one step. Here are the rules for our language:

### Basic Computation Rules

These rules define how to compute results when both operands are already values (numbers):

```
n₁ + n₂ → n₃    (where n₃ is the mathematical sum of n₁ and n₂)
n₁ - n₂ → n₃    (where n₃ is the mathematical difference of n₁ and n₂)
n₁ * n₂ → n₃    (where n₃ is the mathematical product of n₁ and n₂)
n₁ / n₂ → n₃    (where n₃ is the mathematical quotient of n₁ and n₂, and n₂ ≠ 0)
```

### Evaluation Context Rules

These rules define how to make progress when operands need further evaluation:

```
e₁ → e₁'
---------------
e₁ + e₂ → e₁' + e₂
```

```
e₂ → e₂'
---------------
n₁ + e₂ → n₁ + e₂'
```

Similar rules apply for subtraction, multiplication, and division.

The first rule says that if the left operand can take a step, then the entire expression takes a step by reducing that operand. The second rule says that if the left operand is already a value (a number) and the right operand can take a step, then the entire expression takes a step by reducing the right operand.

These rules formalize a left-to-right evaluation order: we fully evaluate the left operand before moving to the right one.

### An Example Derivation

Let's see how `(1 + 2) * (3 + 4)` evaluates using our small-step semantics:

```
(1 + 2) * (3 + 4)
→ 3 * (3 + 4)         (applying the addition rule to 1 + 2)
→ 3 * 7               (applying the addition rule to 3 + 4)
→ 21                  (applying the multiplication rule)
```

Each step shows precisely how the expression transforms according to our rules.

Let's examine a more complex example to demonstrate the role of evaluation context rules. Consider `(2 + 3) * (4 + (5 + 6))`:

```
(2 + 3) * (4 + (5 + 6))
→ 5 * (4 + (5 + 6))          (reducing the left addition)
→ 5 * (4 + 11)               (reducing 5 + 6 within the right expression)
→ 5 * 15                     (reducing 4 + 11)
→ 75                         (reducing 5 * 15)
```

Notice how we always reduce the leftmost reducible expression first, consistent with our left-to-right evaluation order.

## Big-Step Operational Semantics

Where small-step semantics focuses on individual transitions, big-step semantics describes how an expression evaluates directly to its final value. We write `e ⇓ v` to indicate that expression `e` evaluates to value `v`.

For our arithmetic language, the rules are:

### Constants
```
n ⇓ n
```
A number evaluates to itself.

### Addition
```
e₁ ⇓ n₁    e₂ ⇓ n₂
--------------------
  e₁ + e₂ ⇓ n₃
```
where n₃ = n₁ + n₂

This rule says: To evaluate e₁ + e₂, first evaluate e₁ to get value n₁, then evaluate e₂ to get value n₂, then compute n₁ + n₂ to get the final result n₃.

Similar rules apply for subtraction, multiplication, and division.

### An Example with Big-Step Semantics

For `(1 + 2) * (3 + 4)`, the big-step derivation looks like:

```
1 ⇓ 1   2 ⇓ 2          3 ⇓ 3   4 ⇓ 4
-----------              ---------
(1 + 2) ⇓ 3            (3 + 4) ⇓ 7
-----------------------------------
     (1 + 2) * (3 + 4) ⇓ 21
```

This tree-structured derivation shows how we evaluate the entire expression by evaluating its subparts.

## Comparing the Approaches

Both small-step and big-step semantics have their strengths:

- **Small-step semantics** shows each computational step explicitly, making it excellent for reasoning about program execution in detail. It's particularly useful for modeling complex control flow and non-terminating programs.

- **Big-step semantics** is more concise and focuses on the relationship between inputs and outputs, without showing intermediate states. It's often closer to an implementation of an interpreter and can be easier to reason about for simple programs.

The choice between the two approaches depends on what aspects of program behavior you want to emphasize.

## What This Gives Us

Even with our simple arithmetic language, we've demonstrated the core techniques of operational semantics:

1. Precise definitions of valid program syntax
2. Clear rules for how programs evaluate
3. A framework for reasoning about program execution

We've also seen how formal semantics can avoid ambiguity. For example, our rules explicitly specified left-to-right evaluation order for arithmetic expressions, which might be left implicit in an informal language description.

## Conclusion

Operational semantics provides a foundation for understanding how programs execute. By starting with a simple arithmetic language, we've been able to explore the fundamental concepts without getting lost in the complexities of a full programming language.

In the next part, we'll extend our language with variables, conditionals, and functions, transforming it into a small yet powerful functional programming language. This will allow us to see how operational semantics scales to handle more complex language features.

Through this formal approach, we gain precise tools for language design, implementation, and verification—essential for developing reliable and well-understood programming languages.
