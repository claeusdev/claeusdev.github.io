---
layout: post
title: "Recognizing Graph Problems: A Pattern Recognition Guide"
date: 2025-11-22
categories: algorithms graphs
---

Graph problems are everywhere in computer science—from social networks to route planning to dependency resolution. But when you encounter a problem, how do you know it's actually a graph problem? And once you know it's a graph, how do you choose the right representation and algorithm?

This guide will help you develop pattern recognition skills for identifying graph problems and selecting the appropriate approach.

## Is This Even a Graph Problem?

The first step is recognizing when a problem can be modeled as a graph. Look for these telltale signs:

### Relationships Between Entities
If your problem involves **connections**, **relationships**, or **dependencies** between objects, it's likely a graph problem.

**Examples:**
- "Find if two people are connected through mutual friends" → Graph (social network)
- "Determine if all tasks can be completed given their dependencies" → Graph (directed acyclic graph)
- "Find the shortest path between two cities" → Graph (weighted graph)

### Keywords That Signal Graphs
Certain words in problem descriptions are strong indicators:
- **Connected**, **reachable**, **path**
- **Network**, **web**, **tree**
- **Dependencies**, **prerequisites**, **hierarchy**
- **Islands**, **regions**, **components**
- **Neighbors**, **adjacent**, **surrounding**

## Choosing Your Graph Representation

Once you've identified a graph problem, you need to choose how to represent it. The two main options are **adjacency lists** and **adjacency matrices**, but sometimes the problem gives you an **implicit graph** (like a 2D grid).

## Building Your Graph

Before diving into representations, let's understand how to construct graphs from input data. The key distinction is whether your graph is **directed** or **undirected**.

### Directed vs Undirected Graphs

**Undirected Graph:** Edges work both ways. If there's an edge from A to B, you can also go from B to A.
- Examples: Friendships, bidirectional roads, network cables

**Directed Graph:** Edges have a direction. An edge from A to B doesn't mean there's one from B to A.
- Examples: Twitter follows, one-way streets, task dependencies

### Building an Undirected Graph (Adjacency List)

```python
from collections import defaultdict

def build_undirected_graph(edges):
    """
    Build an undirected graph from edge list.
    
    Args:
        edges: List of tuples [(u, v), ...] representing edges
    
    Returns:
        Dictionary mapping each node to its neighbors
    """
    graph = defaultdict(list)
    
    for u, v in edges:
        # Add edge in BOTH directions
        graph[u].append(v)
        graph[v].append(u)
    
    return graph

# Example
edges = [(0, 1), (1, 2), (2, 3), (0, 3)]
graph = build_undirected_graph(edges)
# Result: {0: [1, 3], 1: [0, 2], 2: [1, 3], 3: [2, 0]}
```

### Building a Directed Graph (Adjacency List)

```python
def build_directed_graph(edges):
    """
    Build a directed graph from edge list.
    
    Args:
        edges: List of tuples [(from, to), ...] representing directed edges
    
    Returns:
        Dictionary mapping each node to its outgoing neighbors
    """
    graph = defaultdict(list)
    
    for u, v in edges:
        # Add edge in ONE direction only
        graph[u].append(v)
    
    return graph

# Example: Task dependencies (must complete u before v)
edges = [(0, 1), (0, 2), (1, 3), (2, 3)]
graph = build_directed_graph(edges)
# Result: {0: [1, 2], 1: [3], 2: [3]}
```

### Building with Adjacency Matrix

```python
def build_graph_matrix(n, edges, directed=False):
    """
    Build a graph using adjacency matrix.
    
    Args:
        n: Number of vertices (0 to n-1)
        edges: List of tuples [(u, v), ...] or [(u, v, weight), ...]
        directed: True for directed graph, False for undirected
    
    Returns:
        2D list representing adjacency matrix
    """
    # Initialize matrix with zeros (or infinity for weighted graphs)
    matrix = [[0] * n for _ in range(n)]
    
    for edge in edges:
        if len(edge) == 2:  # Unweighted
            u, v = edge
            weight = 1
        else:  # Weighted
            u, v, weight = edge
        
        matrix[u][v] = weight
        if not directed:
            matrix[v][u] = weight  # Add reverse edge for undirected
    
    return matrix

# Example: Undirected weighted graph
edges = [(0, 1, 5), (1, 2, 3), (0, 2, 7)]
matrix = build_graph_matrix(3, edges, directed=False)
# Result: [[0, 5, 7],
#          [5, 0, 3],
#          [7, 3, 0]]
```

### Handling Edge Cases

**Weighted vs Unweighted:**
```python
# Weighted graph: store (neighbor, weight) tuples
def build_weighted_graph(edges):
    graph = defaultdict(list)
    for u, v, weight in edges:
        graph[u].append((v, weight))
        graph[v].append((u, weight))  # For undirected
    return graph

# Usage
edges = [(0, 1, 4), (1, 2, 3)]
graph = build_weighted_graph(edges)
# Result: {0: [(1, 4)], 1: [(0, 4), (2, 3)], 2: [(1, 3)]}
```

**Self-loops and Multiple Edges:**
```python
# Self-loop: edge from a node to itself
edges = [(0, 0), (0, 1)]  # 0 has a self-loop

# Multiple edges: more than one edge between same nodes
edges = [(0, 1), (0, 1), (1, 2)]  # Two edges from 0 to 1

# Handle duplicates if needed
def build_graph_no_duplicates(edges):
    graph = defaultdict(set)  # Use set instead of list
    for u, v in edges:
        graph[u].add(v)
        graph[v].add(u)
    return {k: list(v) for k, v in graph.items()}
```

### Adjacency List: When to Use

**Best for sparse graphs** (few edges relative to vertices).

**Signals:**
- "Each node has a list of neighbors"
- "Given edges as pairs: `[(1,2), (2,3), (3,4)]`"
- The number of edges is much smaller than $V^2$
- You need to iterate through neighbors frequently

**Example Problem:**
> "Given a list of friend pairs, determine if person A can reach person B through friendships."

**Implementation:**
```python
from collections import defaultdict, deque

def can_reach(edges, start, target):
    # Build adjacency list
    graph = defaultdict(list)
    for u, v in edges:
        graph[u].append(v)
        graph[v].append(u)
    
    # BFS
    visited = set()
    queue = deque([start])
    visited.add(start)
    
    while queue:
        node = queue.popleft()
        if node == target:
            return True
        for neighbor in graph[node]:
            if neighbor not in visited:
                visited.add(neighbor)
                queue.append(neighbor)
    
    return False
```

### Adjacency Matrix: When to Use

**Best for dense graphs** or when you need **O(1) edge lookup**.

**Signals:**
- "Given a 2D array where `matrix[i][j] = 1` means there's an edge"
- You need to frequently check "Is there an edge between node i and node j?"
- The graph is dense (many edges)
- The problem involves matrix operations

**Example Problem:**
> "Given a matrix where `matrix[i][j]` represents the cost to travel from city i to city j, find the minimum cost to visit all cities."

**Implementation:**
```python
def min_cost_all_cities(matrix):
    n = len(matrix)
    # Floyd-Warshall for all-pairs shortest paths
    # See: /2025/11/21/floyd-warshall-algorithm for detailed explanation
    dist = [row[:] for row in matrix]
    
    for k in range(n):
        for i in range(n):
            for j in range(n):
                dist[i][j] = min(dist[i][j], dist[i][k] + dist[k][j])
    
    return dist
```

### Grid/Matrix as Implicit Graph: When to Use

**Best when the problem is posed as a 2D grid** where cells are nodes and edges connect adjacent cells.

**Signals:**
- "Given a 2D grid/matrix"
- "Find connected regions/islands"
- "Navigate from top-left to bottom-right"
- Words like "adjacent", "surrounding", "neighbors" in a grid context

**Example Problem:**
> "Given a grid of 1s and 0s, count the number of islands (connected regions of 1s)."

**Implementation:**
```python
def count_islands(grid):
    if not grid:
        return 0
    
    rows, cols = len(grid), len(grid[0])
    visited = set()
    islands = 0
    
    def dfs(r, c):
        if (r < 0 or r >= rows or c < 0 or c >= cols or 
            (r, c) in visited or grid[r][c] == 0):
            return
        
        visited.add((r, c))
        # Visit all 4 neighbors
        for dr, dc in [(0,1), (1,0), (0,-1), (-1,0)]:
            dfs(r + dr, c + dc)
    
    for r in range(rows):
        for c in range(cols):
            if grid[r][c] == 1 and (r, c) not in visited:
                dfs(r, c)
                islands += 1
    
    return islands
```

## Recognizing Common Graph Problem Patterns

### 1. Connected Components

**How to Recognize:**
- "Find the number of separate groups/clusters/islands"
- "Determine if all nodes are connected"
- "Count disconnected regions"

**Approach:** DFS or BFS from each unvisited node, counting how many times you start a new search.

**Example:** Number of islands, friend circles, network components.

### 2. Shortest Path

**How to Recognize:**
- "Find the minimum number of steps/edges"
- "Shortest distance between two points"
- "Minimum cost to reach destination"

**Approach:**
- **Unweighted graph:** BFS
- **Weighted graph (non-negative):** Dijkstra's algorithm
- **Weighted graph (with negative edges):** Bellman-Ford
- **All-pairs shortest path:** Floyd-Warshall

**Example:** Maze solving, route planning, word ladder.

### 3. Cycle Detection

**How to Recognize:**
- "Detect if there's a circular dependency"
- "Can all tasks be completed?" (topological sort)
- "Is this graph a tree?" (tree = connected + no cycles)

**Approach:**
- **Undirected graph:** DFS with parent tracking
- **Directed graph:** DFS with recursion stack or topological sort

**Example:** Course prerequisites, deadlock detection.

### 4. Topological Sort

**How to Recognize:**
- "Order tasks given dependencies"
- "Prerequisites" or "must complete X before Y"
- Directed acyclic graph (DAG) structure

**Approach:** Kahn's algorithm (BFS with in-degree) or DFS with stack.

**Example:** Build order, course schedule.

### 5. Bipartite Graph

**How to Recognize:**
- "Can we divide into two groups such that..."
- "Is it possible to color the graph with two colors?"
- "Matching" problems

**Approach:** BFS/DFS with 2-coloring.

**Example:** Job assignment, course scheduling with conflicts.

## Decision Tree for Graph Problems

Here's a quick decision tree to help you choose:

```
Is the problem about relationships/connections?
├─ No → Probably not a graph problem
└─ Yes → It's a graph problem
    │
    ├─ Given explicit edges?
    │   ├─ Yes → Use adjacency list (if sparse) or matrix (if dense)
    │   └─ No → Check if it's a grid/matrix
    │
    ├─ Need to find connected regions?
    │   └─ Use DFS/BFS for connected components
    │
    ├─ Need shortest path?
    │   ├─ Unweighted → BFS
    │   ├─ Weighted (non-negative) → Dijkstra
    │   └─ Weighted (with negatives) → Bellman-Ford
    │
    ├─ Need to detect cycles or order by dependencies?
    │   └─ Use DFS or topological sort
    │
    └─ Need to partition into two groups?
        └─ Check if bipartite with 2-coloring
```

## Practical Tips

1. **Draw it out:** Sketch the problem as nodes and edges. If it makes sense, it's a graph.

2. **Count the edges:** If $E \approx V^2$, use a matrix. If $E \ll V^2$, use a list.

3. **Look at constraints:** 
   - Small $V$ (< 100)? Matrix might be fine.
   - Large $V$ (> 10,000)? Definitely use adjacency list.

4. **Consider the operations:** If you're checking "is there an edge?" repeatedly, use a matrix or set-based adjacency list.

## Conclusion

Recognizing graph problems is a skill that improves with practice. Start by looking for relationships and connections in the problem statement. Then, choose your representation based on the graph's density and the operations you'll perform most frequently.

With these patterns in mind, you'll be able to quickly identify graph problems and select the right tools to solve them efficiently.
