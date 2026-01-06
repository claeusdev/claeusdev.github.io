---
title: "Branded Types in TypeScript: From Structural to Nominal Typing"
description: "How to achieve nominal typing in TypeScript with branded types, preventing subtle runtime bugs by making types explicitly incompatible even when their structures match."
date: 2026-01-06
author: "Nana Adjei Manu"
categories: "engineering"
image: "/branded-types-typescript.png"
tags: ["TypeScript", "Type System", "Type Safety", "Programming Languages"]
---

![Branded Types in TypeScript](/branded-types-typescript.png)

TypeScript uses structural typing, where types are compatible as long as their structures match. Sometimes we really need the explicit compatibility check for our declared types.

In this post I'll show how we can achieve nominal typing in TypeScript with branded types, where types are only compatible if they're explicitly declared so.

## The Problem with Structural Typing

In TypeScript, types are compared by their structure, not their name:

```typescript
type UserId = string;
type PostId = string;

function getUser(id: UserId): User {}
function getPost(id: PostId): Post {}

const userId: UserId = "user_123";
const postId: PostId = "post_123";

// These function calls below will compile but it's a runtime bug
getUser(postId);
getPost(userId);
```

As shown above, the calls to `getUser` and `getPost` compile but can lead to subtle bugs that appear only at runtime.

### Another Example

Say we want to convert some units. We may have some code like this:

```typescript
type Meters = number;
type Feet = number;
type Kilograms = number;

function calculateSpeed(distance: Meters, time: number): number {
  return distance / time;
}

const distanceInFeet: Feet = 1000;

calculateSpeed(distanceInFeet, 20); // compiles
```

Also shown above, the call to `calculateSpeed` with `distanceInFeet` should not ideally compile but it does and also a runtime bug as the value returned is a number but not what we want.

These are some of the dangers that limit the TypeScript we write sometimes to only an autocomplete and documentation tool. We can do more than that, that's where the concept of **Branded Types** comes in.

## What are Branded Types?

Also called **tagged types** or **opaque types**, while mostly known as a concept from TypeScript, has some deep roots in programming language theory.

1. **Modula-3 (1980s)**: Modula-3, also a structurally typed language, introduced the `BRANDED` keyword to distinguish otherwise identical types. I believe this inspired the concept in TypeScript.

2. **Generativity**: In type theory, a type is 'generative' if it creates a brand new distinct type when its definition is evaluated. This is in contrast with "transparent" types or type aliases. Branded types are a form of generativity.

3. **Existential Types**: Branded types are mathematically similar to existential types or more commonly known as ADT (abstract data types). When you 'brand' a type, you essentially hide the internal structure from the outside world (makes it opaque), thus ensuring that only functions authorized to "see" inside the brand can affect it.

In short, branded types add a unique "brand" to a type to make it nominally distinct.

## How It Works

Add a unique brand using intersection with a **phantom** property. Phantom means it only exists at compile time but not runtime.

```typescript
type UserId = string & { readonly __brand: "UserId" };
type PostId = string & { readonly __brand: "PostId" };

function getUser(id: UserId): User {}
function getPost(id: PostId): Post {}
```

Just by adding the `__brand` phantom type, we can distinguish between `UserId` and `PostId` unlike before:

```typescript
// Now these 2 are incompatible
const userId = "user_123" as UserId;
const postId = "post_123" as PostId;

getUser(userId); // this is fine
getUser(postId); // compile error: PostId not assignable to UserId

const str = "user-599";

getUser(str); // string also not assignable to UserId
```

One thing to note though is that, at runtime, a `UserId/PostId` type is still a string. The `__brand` property we added doesn't exist because they're only phantom.

At this point, we have described an issue and described a solution with some examples. Let's attempt to use our new found knowledge to solve some day to day TypeScript developer problems.

## Creating Branded Types

If we're going to be productive JavaScript developers, we use TypeScript and now that we've learned how to brand our types, let's become more productive by building utilities that make our life easier.

### Generic Brand Helper

Let's create a reusable brand type:

```typescript
type Brand<T, B extends string> = T & { readonly __brand: B };
```

The above just means: We're creating an alias `Brand`, that's parameterized by two types `T` and `B`, where `B` is a type that passes for all strings. Then we "brand" our type `T` with the type `B`.

From this, we can now have several branded types:

```typescript
type UserId = Brand<string, "UserId">;
type PostId = Brand<string, "PostId">;
type Email = Brand<string, "Email">;

type Meters = Brand<number, "Meters">;

// ... think of as many branded types as you want
```

### Using Symbols for our Brands

Starting from ES6, symbols became a primitive data type, just like number and string. They're just values created by calling the `Symbol` constructor. [Learn more](https://www.typescriptlang.org/docs/handbook/symbols.html).

We can then use symbols as unique type literals by using the keyword `unique`. We can now create really unique "brands" with unique symbols.

```typescript
declare const brandSymbol: unique symbol;

type Brand<T, B> = T & { [brandSymbol]: B };

// can use them just as before
type UserId = Brand<string, "UserId">;
type PostId = Brand<string, "PostId">;
type Email = Brand<string, "Email">;
```

From the snippet above, we can see that we've been able to create a Brand that resembles the one before but at this point we get:

#### 1. Collision Resistance (Safety)

Using a string key like `__brand` or `_type`, there's a small risk that a real object from a library or API might actually have a property named `__brand` but using a `unique symbol` which doesn't get beyond compilation, it's impossible for any other code to "collide" with our brand.

#### 2. Autocomplete Cleanup (DevEx)

When we use a string brand like `__brand`, you may see it in your IDE's autocomplete list when you type `someObj.` which if you're like me, you probably find it very annoying. Symbols are not strings, they're usually hidden from standard autocomplete suggestions.

### How to Use Our Brand?

Since `brandSymbol` doesn't exist at runtime, we can't naturally create these types. Use "Type assertion" or casting to tell TypeScript to trust that we know what we're doing.

Instead of using `as`, create "smart" constructor functions:

```typescript
type UserId = Brand<string, "UserId">;
const someId: UserId = "1234"; // can't assign regular strings
const myId: UserId = "1234" as UserId; // works but repetitive

// smart constructor, only way to create a UserId
function createUserId(id: string): UserId {
  return id as UserId;
}

// now we can use the constructor to create userIds
const userId = createUserId("user-124");
```

## Validation with Branded Types

The real power of branded types comes from coupling them with validation.

Let's validate some positive numbers:

```typescript
type PositiveNumber = Brand<number, "PositiveNumber">;
type NonNegativeNumber = Brand<number, "NonNegativeNumber">;
type Integer = Brand<number, "Integer">;
type PositiveInteger = Brand<number, "PositiveInteger">;

function assertPositive(n: number): asserts n is PositiveNumber {
  if (n <= 0) {
    throw new Error(`Expected a positive number but got ${n}`);
  }
}

function toPositive(n: number): PositiveNumber {
  assertPositive(n);
  return n as PositiveNumber;
}

function toPositiveInteger(n: number): PositiveInteger {
  if (n <= 0 || !Number.isInteger(n)) {
    throw new Error(`Expected positive integer but got ${n}`);
  }

  return n as PositiveInteger;
}

// Usage
function divide(a: number, b: PositiveNumber): number {
  // since b is guaranteed to be positive, no division by zero
  return a / b;
}

const positiveB = toPositive(5);
console.log(divide(10, positiveB)); // logs 2

// divide(10, -5) // Error: number not assignable to PositiveNumber
```

## Common Use Cases for Branded Types

You may be wondering, why do I need all of this? You probably don't but also you probably also don't know that you do.

The use cases are quite more common than you think:

```typescript
type USD = Brand<number, "USD">;
type EUR = Brand<number, "EUR">;
type GBP = Brand<number, "GBP">;

// util functions to convert some currencies to CURRENCIES
function usd(amount: number): USD {
  return (Math.round(amount * 100) / 100) as USD;
}

function eur(amount: number): EUR {
  return (Math.round(amount * 100) / 100) as EUR;
}

// Conversion requires explicit exchange rate
function usdToEur(amount: USD, rate: number): EUR {
  return (amount * rate) as EUR;
}

// Can't mix currencies
function addUSD(a: USD, b: USD): USD {
  // return a + b, Error: number not assignable to USD
  return (a + b) as USD;
}

const price = usd(99.99);
const discount = usd(10);
const total = addUSD(price, discount);

// addUSD(usd(100), eur(50));  // Error!
```

From the above snippet, the beauty of type branding shows, we get explicit validation of currencies. Imagine the number of potential runtime bugs you can safely skip just by branding your types.

## Why Use Libraries?

At this point we have been able to run through quickly what branded types are and the benefits we can get from them.

If you've paid attention at all you'd notice there are some powerful and popular libraries that already give you the ability to add branded types to your applications.

### 1. Zod

If you haven't already figured out:

```typescript
import { z } from "zod";

// Define schema with brand
const EmailSchema = z.string().email().brand<"Email">();
type Email = z.infer<typeof EmailSchema>;

// Parse and validate
const email = EmailSchema.parse("alice@example.com");
// email is branded Email type

// Invalid throws
// EmailSchema.parse("invalid");  // throws ZodError
```

### 2. io-ts

`io-ts` is another example of a library that allows us to create branded types.

### 3. NewType Pattern

We can also use the `NewType` pattern from Haskell but that's a whole other diversion.

## Summary

I hope I have been able to quickly give you some lightbulb moments as you've read through this post. As a short summary of what we've gone through together:

1. **Use smart constructors**: Don't rely on `as` casts too much in application code
2. **Add validation**: Brands are most useful when they guarantee invariants
3. **Name your brands clearly**: `Brand<string, "Email">` reads better than `Brand<string, "E">`
4. **Consider runtime impact**: Brands are compile time only

I also would like you to remember where Branded Types should **not** be used:

1. Simple cases where type aliases suffice
2. When the smart constructors just isn't worth it
3. For internal, short-lived values
4. When all values of the type are valid

---

Branded types are a powerful tool in the TypeScript developer's arsenal. They bridge the gap between structural and nominal typing, giving you the flexibility of TypeScript's type system while adding the safety of explicit type checking. Use them wisely, and they'll save you from countless runtime bugs.
