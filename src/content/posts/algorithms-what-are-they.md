---
title: "Algorithms: What are they?"
description: "An introduction to algorithms in computer science. Learn what computational problems are, the difference between decision and optimization problems, and why algorithm design matters."
date: 2024-02-24
author: "Nana Adjei Manu"
categories: "algorithms"
tags: ["Algorithms", "Computer Science", "Programming", "Data Structures"]
---

### What are Algorithms?

An algorithm is a step-by-step procedure for solving a computational problem. Now, you may wonder what a step is, and then you would wonder what a computational problem is.
A computational problem is any problem that can be solved with a set of standard computational operations and a step for each operation in the set of operations involved in solving the problems.

There are two types of problems: `decision problems`, which are essentially `Yes` or `No` problems. For example, given that a list consists of integers, determine whether it's possible to find two that sum up to an even number and `Optimisation problems` are the second type of problems that need to determine some computations under certain constraints. e.g. Given a set of tasks, each with a deadline and profit, choose a way to schedule them to maximise the total profit of tasks completed before their deadline.

In computing, algorithms express a high-level "idea" to solve a problem. This "idea" is a programming language or machine architecture agnostic. When you take your favourite programming language out of the solution of a problem, what remains can be thought of as your algorithm. We may be able to express algorithms in plain English because, as earlier mentioned, it's an idea. However, English expressions can be vague or lack precision when translated from one form to the other, and precision matters a lot in designing correct algorithms. `Pseudocode` is a structure that reads like a mix of programming English but with no rigid syntax and is usually correct as long as its meaning is clear.

Below is an example: Given a list of integers A of size n, find the largest element.

```c++
Input: A[1..n] of size n
Output: number x in A

f(A, n):
    x = A[0]
    for i = 1 to n do
        if A[i] > x do
            x = A[i]
        endif
    endfor
    return x
```

The above looks familiar, right? It seems like a programming language procedure, but copying and pasting it into your editor and running it will not work. It's still easy to reason about, right? We're just scanning through the entire list, comparing the current integer with the previous largest at each point.

In programming, an algorithm is any function that takes value(s) as input, performs some computation(s), and returns some output within a set amount of time. We can't have an algorithm without a problem; algorithms are said to provide solutions to a problem that states what the algorithm must do to provide the desired output.

What do we gain by saying a lot of things without an example? In programming, one of the most common things we do is sorting. It's only right that our first example should be a sorting one.

> Given a list of numbers l = {12, 5, 90, 78, 56, 1000}, we want to sort them in increasing order.

```c++
# After our algorithm runs, We expect the output to be { 5, 12, 56, 78, 90, 1000}.
# Below is a very short pseudocode

sort(l):
    # some bad sorting algorithm
    returns { 5, 12, 56, 78, 90, 1000 }
```

As shown in the example above, an algorithm is `correct` if it solves the problem given any input and returns the expected output in finite time. It is `incorrect` if it solves the problem with some input or returns the wrong output.

### Why do we need to study Algorithms?

There are many valuable reasons why we need to study algorithms and how to design efficient ones. Usually, the most straightforward solution to a problem is not the best or even the `correct` solution or most efficient.

Many real-life situations and problems require efficient solutions. A very good example is finding the shortest path from your house to your date when you're running late and there's traffic. Scientists also use DNA sequencing to better understand diseases. These both usually involve computations on very large datasets, as compared to the one I have shown above for a list of finite items.

To design efficient and correct algorithms to solve these problems, we need to develop a deep understanding of the problem and its building blocks. However, some general techniques and design paradigms have been useful in the past to solve some of these problems and challenges. We study Algorithms and their design to leverage these paradigms and techniques to solve our own problems.

You may be wondering, all of this is nice, but why should we care about designing efficient algorithms while we're at it? Computers have gotten faster due to RAM and CPU power, but given an arbitrarily large input, we still would like to see a correct output in our lifetime. If indeed we get an output in our lifetime, we should make sure we don't kill our computers.

You see, computing time is bound by its underlying hardware resources, such as memory space. Because we don't have infinite time and memory, we need to design and choose algorithms that use our resources efficiently.

Different algorithms will solve a problem with different efficiency. Let's go back to our most crucial sorting problem once again. There are two famous algorithms for sorting: `Insertion` and `Merge` sort. We need to find the best solution given the constraints related to the problem, i.e., the optimisation problem.

### Summary

Algorithms are not about the programming tricks you have probably heard about, as not all of them improve algorithm scalability. They're about designing computational operations with "Algorithmic thinking", which is usually a different approach and mindset altogether.
