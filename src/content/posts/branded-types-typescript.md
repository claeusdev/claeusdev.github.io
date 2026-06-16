---
title: "Branded Types in TypeScript: From Structural to Nominal Typing"
description: "How to achieve nominal typing in TypeScript with branded types, preventing subtle runtime bugs by making types explicitly incompatible even when their structures match."
date: 2026-01-06
author: "Nana Adjei Manu"
categories: "engineering"
image: "/branded-types-typescript.webp"
tags: ["TypeScript", "Type System", "Type Safety", "Programming Languages"]
---

![Branded Types in TypeScript](/branded-types-typescript.webp)

You've just shipped a critical bug to production. A user's bank account was debited in euros, but credited in dollars. The amounts matched perfectly — `100` is `100` after all but your currency conversion logic silently failed. TypeScript didn't catch it. Your tests didn't catch it. The code compiled without a warning.

This is the dark side of structural typing.

TypeScript compares types by their structure, not their identity. If two types have the same shape, they're interchangeable, even when they shouldn't be. A `UserId` is just a string. A `PostId` is just a string. TypeScript sees no difference.

But there's a way to tell TypeScript: "No, these types are fundamentally different, even if they look the same." That's where **branded types** come in, a technique that brings nominal typing to TypeScript's structural typing.

## The Problem with Structural Typing

Let me show you exactly how this happens. Here's some perfectly valid TypeScript code:

```typescript
type UserId = string;
type PostId = string;

function getUser(id: UserId): User {
  // Fetch user from database using id
}

function getPost(id: PostId): Post {
  // Fetch post from database using id
}

const userId: UserId = "user_123";
const postId: PostId = "post_123";

// TypeScript allows this but it's wrong!
getUser(postId); // Compiles, Runtime bug: fetches wrong data
getPost(userId); // Compiles, Runtime bug: fetches wrong data
```

TypeScript sees both `UserId` and `PostId` as strings. Since they have the same structure, they're compatible. The compiler is happy, but your application is broken.

### A More Dangerous Example

Imagine you're building a physics simulation or a fitness app that tracks running distances:

```typescript
type Meters = number;
type Feet = number;

function calculateSpeed(distance: Meters, time: number): number {
  return distance / time; // meters per second
}

const distanceInFeet: Feet = 1000;

// This compiles, but the result is completely wrong!
const speed = calculateSpeed(distanceInFeet, 20); // Treats feet as meters
```

The function expects meters, but you passed feet. The calculation runs, returns a number, and TypeScript is satisfied. But your speed calculation is off by a factor of 3.28. In a production system, this could mean incorrect dosages, wrong billing, or failed safety checks.

**This is the core problem**: TypeScript's structural typing makes it impossible to distinguish between semantically different values that happen to share the same underlying type. We need a way to make types nominally distinct.

## What are Branded Types?

Branded types (also called **tagged types** or **opaque types**) are a technique for creating nominally distinct types in structurally-typed languages. While popularized in the TypeScript community, the concept has deep roots in programming language theory:

**Modula-3 (1980s)**: This structurally-typed language introduced the `BRANDED` keyword to distinguish otherwise identical types. This is likely where TypeScript drew inspiration.

**Generativity**: In type theory, a type is "generative" if each evaluation of its definition creates a brand new, distinct type. This contrasts with "transparent" types (type aliases), which are just names for existing types. Branded types implement a form of generativity.

**Existential Types**: Branded types are mathematically related to existential types and abstract data types (ADTs). When you "brand" a type, you hide its internal structure from the outside world, making it opaque. Only code that's explicitly authorized can "see through" the brand.

### The Core Idea

The fundamental insight is simple: **add a unique marker to a type to make it nominally distinct**, even if the underlying structure is the same.

## How It Works

The technique uses TypeScript's intersection types to add a **phantom property** — a property that exists only at compile time, never at runtime.

Here's the pattern:

```typescript
type UserId = string & { readonly __brand: "UserId" };
type PostId = string & { readonly __brand: "PostId" };

function getUser(id: UserId): User {
  // Implementation
}

function getPost(id: PostId): Post {
  // Implementation
}
```

The `& { readonly __brand: "UserId" }` part is the "brand." It's an intersection with an object type that has a `__brand` property. But here's the key: **this property doesn't exist at runtime**. It's purely a compile-time marker.

Now watch what happens:

```typescript
// Now these 2 are incompatible
const userId = "user_123" as UserId;
const postId = "post_123" as PostId;

getUser(userId); // Works
getUser(postId); // Error: Type 'PostId' is not assignable to type 'UserId'

const regularString = "user_789";
getUser(regularString); // Error: Type 'string' is not assignable to type 'UserId'
```

TypeScript now treats `UserId` and `PostId` as fundamentally different types, even though they're both strings underneath. The brand makes them incompatible.

**Important**: At runtime, `UserId` and `PostId` are still just strings. The `__brand` property is erased during compilation. This means:

- Zero runtime overhead
- No performance cost
- No memory impact
- Pure compile-time safety

Now that we understand the basic mechanism, let's build reusable utilities to make working with branded types more ergonomic.

## Creating Branded Types

Writing `string & { readonly __brand: "UserId" }` every time gets tedious. Let's create a reusable utility.

### Generic Brand Helper

Here's a generic `Brand` type that works for any base type:

```typescript
type Brand<T, BrandName extends string> = T & { readonly __brand: BrandName };
```

This is a type-level function that takes:

- `T`: The underlying type (string, number, etc.)
- `BrandName`: A unique string literal to identify this brand

Now we can create branded types concisely:

```typescript
type UserId = Brand<string, "UserId">;
type PostId = Brand<string, "PostId">;
type Email = Brand<string, "Email">;

type Meters = Brand<number, "Meters">;
type Feet = Brand<number, "Feet">;
type USD = Brand<number, "USD">;
```

Much cleaner! But we can do even better.

### Using Symbols for our Brands

For even better type safety, we can use TypeScript's `unique symbol` feature instead of string literals.

```typescript
declare const brandSymbol: unique symbol;

type Brand<T, BrandName> = T & { [brandSymbol]: BrandName };

// Usage remains the same
type UserId = Brand<string, "UserId">;
type PostId = Brand<string, "PostId">;
type Email = Brand<string, "Email">;
```

Why is this better? Two key advantages:

**1. Collision Resistance**

With a string-based brand like `__brand`, there's a small risk that a real object from a third-party library might actually have a property named `__brand`. Using a `unique symbol` eliminates this risk entirely — symbols are guaranteed to be unique, and this one only exists at the type level.

**2. Cleaner IDE Experience**

When you use a string property like `__brand`, it can show up in your IDE's autocomplete when you type `someObj.`. This is noise. Symbols don't appear in autocomplete, keeping your development experience clean.

### Smart Constructors: The Right Way to Create Branded Types

Since the brand property doesn't exist at runtime, we can't create branded types naturally. We need to use type assertions (`as`), but doing this everywhere is error-prone and defeats the purpose of type safety.

The solution: **smart constructor functions** that encapsulate the type assertion in one place.

```typescript
type UserId = Brand<string, "UserId">;

// Not recommended : Type assertions scattered everywhere
const userId1: UserId = "1234" as UserId;
const userId2: UserId = "5678" as UserId;
const userId3: UserId = "9012" as UserId;

// Recommended : Single smart constructor
function createUserId(id: string): UserId {
  return id as UserId;
}

const userId1 = createUserId("1234");
const userId2 = createUserId("5678");
const userId3 = createUserId("9012");
```

This is better because:

- Type assertion logic is centralized
- Easy to add validation later (we'll see this next)
- Clear intent: "this is how you create a UserId"
- Easier to refactor if the brand implementation changes

## Validation with Branded Types

Here's where branded types become truly powerful: **combining type safety with runtime validation**.

Smart constructors can validate input before returning a branded type. This guarantees that any value with a branded type has passed validation.

### Example: Positive Numbers

```typescript
type PositiveNumber = Brand<number, "PositiveNumber">;
type PositiveInteger = Brand<number, "PositiveInteger">;

// Using TypeScript's assertion functions
function assertPositive(n: number): asserts n is PositiveNumber {
  if (n <= 0) {
    throw new Error(`Expected a positive number but got ${n}`);
  }
}

// Smart constructor with validation
function toPositive(n: number): PositiveNumber {
  assertPositive(n);
  return n as PositiveNumber; // Safe because we just validated
}

function toPositiveInteger(n: number): PositiveInteger {
  if (n <= 0 || !Number.isInteger(n)) {
    throw new Error(`Expected positive integer but got ${n}`);
  }
  return n as PositiveInteger;
}
```

Now look at what we can do:

```typescript
function divide(a: number, b: PositiveNumber): number {
  // No need to check if b is zero: the type guarantees it's positive!
  return a / b;
}

const validNumber = toPositive(5);
console.log(divide(10, validNumber)); // 2

// These won't compile:
// divide(10, -5);  // Error: number not assignable to PositiveNumber
// divide(10, 0);   // Error: number not assignable to PositiveNumber

// This will throw at the validation point:
// const invalid = toPositive(-5); // Throws: Expected a positive number but got -5
```

**The key insight**: Once you have a `PositiveNumber`, you know it's been validated. The type system enforces that you can't create one without going through the validator. This moves error checking to the boundary of your system, making your core logic simpler and safer.

## Common Use Cases for Branded Types

Branded types shine in domains where mixing up similar values causes bugs. Here are some real-world scenarios:

### Currency Handling

```typescript
type USD = Brand<number, "USD">;
type EUR = Brand<number, "EUR">;
type GBP = Brand<number, "GBP">;

// Smart constructors with rounding
function usd(amount: number): USD {
  return (Math.round(amount * 100) / 100) as USD;
}

function eur(amount: number): EUR {
  return (Math.round(amount * 100) / 100) as EUR;
}

// Currency conversion requires explicit exchange rate
function usdToEur(amount: USD, exchangeRate: number): EUR {
  return eur(amount * exchangeRate);
}

// Operations on same currency
function addUSD(a: USD, b: USD): USD {
  return usd(a + b);
}

// Usage
const price = usd(99.99);
const tax = usd(8.5);
const total = addUSD(price, tax); // Works

const euroPrice = eur(85.0);
// addUSD(price, euroPrice); // Error: Can't mix USD and EUR
```

This prevents catastrophic bugs like:

- Adding dollars to euros
- Displaying prices in the wrong currency
- Applying wrong exchange rates
- Mixing up currency symbols

### Other Common Use Cases

```typescript
// IDs and identifiers
type UserId = Brand<string, "UserId">;
type OrderId = Brand<string, "OrderId">;
type SessionToken = Brand<string, "SessionToken">;

// Units of measurement
type Meters = Brand<number, "Meters">;
type Kilometers = Brand<number, "Kilometers">;
type Celsius = Brand<number, "Celsius">;
type Fahrenheit = Brand<number, "Fahrenheit">;

// Validated strings
type Email = Brand<string, "Email">;
type URL = Brand<string, "URL">;
type PhoneNumber = Brand<string, "PhoneNumber">;

// Time representations
type UnixTimestamp = Brand<number, "UnixTimestamp">;
type ISODateString = Brand<string, "ISODateString">;
```

## Branded Types in Popular Libraries

While rolling your own branded types is straightforward, several popular libraries have built-in support that combines branding with validation.

### Zod

[Zod](https://zod.dev) is a TypeScript-first schema validation library that supports branded types out of the box:

```typescript
import { z } from "zod";

// Define schema with brand
const EmailSchema = z.string().email().brand<"Email">();
type Email = z.infer<typeof EmailSchema>;

const PositiveNumberSchema = z.number().positive().brand<"PositiveNumber">();
type PositiveNumber = z.infer<typeof PositiveNumberSchema>;

// Parse and validate
const email = EmailSchema.parse("alice@example.com"); // Returns branded Email
const num = PositiveNumberSchema.parse(42); // Returns branded PositiveNumber

// Invalid input throws ZodError
// EmailSchema.parse("not-an-email"); // Throws
// PositiveNumberSchema.parse(-5);     // Throws
```

**Benefits**: Validation + branding in one step, runtime type checking, excellent error messages.

### io-ts

[io-ts](https://github.com/gcanti/io-ts) provides runtime type checking with branded types:

```typescript
import * as t from "io-ts";

// Define a branded codec
interface PositiveBrand {
  readonly Positive: unique symbol;
}

const Positive = t.brand(
  t.number,
  (n): n is t.Branded<number, PositiveBrand> => n > 0,
  "Positive"
);

type Positive = t.TypeOf<typeof Positive>;

// Decode and validate
const result = Positive.decode(42);
// result is Either<Errors, Positive>
```

**Benefits**: Functional programming style, composable validators, strong type inference.

### When to Use Libraries vs. Rolling Your Own

**Use libraries when:**

- You need runtime validation from external sources (APIs, user input)
- You want comprehensive error messages
- You're already using the library for other validation

**Roll your own when:**

- You only need compile-time safety
- You want zero dependencies
- You need custom validation logic
- You're working with internal, trusted data

## Summary: Best Practices

Here are the key takeaways for using branded types effectively:

### Do's

1. **Use smart constructors** — Centralize type assertions in constructor functions, don't scatter `as` casts throughout your codebase

2. **Add validation** — Branded types are most powerful when they guarantee invariants (positive numbers, valid emails, etc.)

3. **Name brands clearly** — `Brand<string, "Email">` is self-documenting; `Brand<string, "E">` is cryptic

4. **Consider unique symbols** — For production code, prefer `unique symbol` over string brands to avoid collisions

5. **Document your brands** — Add JSDoc comments explaining what the brand guarantees

### Don'ts

1. **Don't overuse** — Simple type aliases are fine when all values are valid

2. **Don't brand internal values** — Short-lived, internal values don't need branding

3. **Don't skip validation** — If you're branding for safety, actually validate in the constructor

4. **Don't forget runtime** — Brands are compile-time only; you still need runtime checks at system boundaries

## Final Thoughts

Remember that bug from the beginning? The one where euros and dollars got mixed up?

```typescript
// Before: Compiles, breaks in production
function processPayment(amount: number, currency: string) {
  // Hope and pray the currency matches the amount
}

// After: Won't compile if you mix currencies
function processPayment(amount: USD) {
  // Type system guarantees this is USD
}
```

Branded types turn runtime bugs into compile-time errors. They make impossible states unrepresentable. They let you encode business rules directly into your type system.

TypeScript's structural typing is powerful, but sometimes you need nominal guarantees. Branded types give you the best of both worlds: the flexibility of structural typing when you want it, and the safety of nominal typing when you need it.

Use them wisely, and they'll save you from countless debugging sessions, production incidents, and late-night hotfixes.

---
