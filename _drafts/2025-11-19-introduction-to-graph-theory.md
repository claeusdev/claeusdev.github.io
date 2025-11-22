---
layout: post
title: "Introduction to Graph Theory: From Mathematics to Code"
date: 2025-11-19
categories: algorithms graphs mathematics
---

Graphs are one of the most fundamental and versatile data structures in computer science. They model relationships, connections, and networks—from social media friendships to city road maps to the internet itself. But before we can use graphs effectively in code, we need to understand their mathematical foundation.

This article builds graphs from the ground up: starting with the mathematical intuition, then translating that into practical programming concepts with well-documented code examples.

## What is a Graph? (Mathematical Definition)

In mathematics, a **graph** $G$ is an ordered pair $G = (V, E)$ where:

- $V$ is a set of **vertices** (also called nodes)
- $E$ is a set of **edges** (connections between vertices)

Each edge connects two vertices. We write an edge as an unordered pair $(u, v)$ where $u, v \in V$.

### Example: A Simple Graph

Consider a graph representing friendships:

```
V = {Alice, Bob, Carol, Dave}
E = {(Alice, Bob), (Bob, Carol), (Carol, Dave), (Alice, Dave)}
```

Visually:

```
Alice --- Bob
  |        |
  |        |
Dave --- Carol
```

This is an **undirected graph** because friendships are mutual. If Alice is friends with Bob, then Bob is friends with Alice.

## Directed vs Undirected Graphs

### Undirected Graph

Edges have no direction. $(u, v)$ and $(v, u)$ represent the same edge.

**Mathematical notation:** $E \subseteq \{\{u, v\} : u, v \in V, u \neq v\}$

**Examples:** 
- Friendships on Facebook
- Bidirectional roads
- Undirected network cables

### Directed Graph (Digraph)

Edges have direction. $(u, v)$ means "from $u$ to $v$" and is different from $(v, u)$.

**Mathematical notation:** $E \subseteq V \times V$ (Cartesian product)

**Examples:**
- Twitter follows (you follow someone, they don't necessarily follow you back)
- One-way streets
- Web page links

**Visual representation:**

```
Undirected:     Directed:
A --- B         A --> B
                A <-- C
```

## Weighted Graphs

Sometimes edges have **weights** (costs, distances, capacities). A weighted graph is a triple $G = (V, E, w)$ where $w: E \to \mathbb{R}$ is a weight function.

**Example:** Road network where weights are distances in kilometers.

```
    5km        3km
A ------- B ------- C
    |              |
   7km           2km
    |              |
    D ------------ E
         4km
```

## Graph Properties

### Degree

The **degree** of a vertex is the number of edges connected to it.

For vertex $v$: $\text{deg}(v) = |\{e \in E : v \in e\}|$

In a directed graph:
- **In-degree:** Number of incoming edges
- **Out-degree:** Number of outgoing edges

### Path

A **path** is a sequence of vertices $v_1, v_2, \ldots, v_k$ where each consecutive pair $(v_i, v_{i+1})$ is an edge.

**Path length:** Number of edges in the path (or sum of weights in weighted graphs).

### Cycle

A **cycle** is a path that starts and ends at the same vertex, with no repeated edges.

### Connected Graph

An undirected graph is **connected** if there's a path between every pair of vertices.

A directed graph is **strongly connected** if there's a directed path from every vertex to every other vertex.

## From Math to Code: Representing Graphs

Now let's translate these mathematical concepts into code. We'll use Python for clarity.

### Representation 1: Adjacency List

An adjacency list stores, for each vertex, a list of its neighbors.

**Mathematical intuition:** For each $v \in V$, store the set $\{u : (v, u) \in E\}$.

```python
from collections import defaultdict

class Graph:
    """
    Graph represented as an adjacency list.
    
    Attributes:
        vertices: Set of all vertices
        edges: Dictionary mapping each vertex to its list of neighbors
        directed: Whether the graph is directed
    """
    
    def __init__(self, directed=False):
        """
        Initialize an empty graph.
        
        Args:
            directed: If True, edges are directed. If False, undirected.
        """
        self.vertices = set()
        self.edges = defaultdict(list)
        self.directed = directed
    
    def add_vertex(self, v):
        """
        Add a vertex to the graph.
        
        Mathematical: Add v to V
        """
        self.vertices.add(v)
        if v not in self.edges:
            self.edges[v] = []
    
    def add_edge(self, u, v, weight=None):
        """
        Add an edge to the graph.
        
        Mathematical: Add (u, v) to E
        For undirected graphs, also add (v, u)
        
        Args:
            u: Source vertex
            v: Destination vertex
            weight: Optional edge weight
        """
        # Ensure vertices exist
        self.add_vertex(u)
        self.add_vertex(v)
        
        # Add edge u -> v
        if weight is None:
            self.edges[u].append(v)
        else:
            self.edges[u].append((v, weight))
        
        # For undirected graphs, add reverse edge
        if not self.directed:
            if weight is None:
                self.edges[v].append(u)
            else:
                self.edges[v].append((u, weight))
    
    def get_neighbors(self, v):
        """
        Get all neighbors of vertex v.
        
        Mathematical: Return {u : (v, u) ∈ E}
        """
        return self.edges[v]
    
    def degree(self, v):
        """
        Get the degree of vertex v.
        
        Mathematical: deg(v) = |{e ∈ E : v ∈ e}|
        """
        return len(self.edges[v])
    
    def __repr__(self):
        """String representation of the graph."""
        lines = [f"Graph(directed={self.directed})"]
        lines.append(f"Vertices: {sorted(self.vertices)}")
        lines.append("Edges:")
        for v in sorted(self.vertices):
            lines.append(f"  {v}: {self.edges[v]}")
        return "\n".join(lines)

# Example: Create the friendship graph
g = Graph(directed=False)
g.add_edge("Alice", "Bob")
g.add_edge("Bob", "Carol")
g.add_edge("Carol", "Dave")
g.add_edge("Alice", "Dave")

print(g)
# Output:
# Graph(directed=False)
# Vertices: ['Alice', 'Bob', 'Carol', 'Dave']
# Edges:
#   Alice: ['Bob', 'Dave']
#   Bob: ['Alice', 'Carol']
#   Carol: ['Bob', 'Dave']
#   Dave: ['Carol', 'Alice']
```

### Representation 2: Adjacency Matrix

An adjacency matrix is a 2D array where `matrix[i][j] = 1` if there's an edge from vertex $i$ to vertex $j$.

**Mathematical intuition:** Define a matrix $A$ where $A_{ij} = 1$ if $(v_i, v_j) \in E$, else $0$.

```python
class GraphMatrix:
    """
    Graph represented as an adjacency matrix.
    
    Attributes:
        n: Number of vertices
        matrix: 2D list where matrix[i][j] represents edge from i to j
        directed: Whether the graph is directed
    """
    
    def __init__(self, n, directed=False):
        """
        Initialize a graph with n vertices.
        
        Args:
            n: Number of vertices (labeled 0 to n-1)
            directed: If True, edges are directed
        """
        self.n = n
        self.directed = directed
        # Initialize n x n matrix with zeros
        self.matrix = [[0] * n for _ in range(n)]
    
    def add_edge(self, u, v, weight=1):
        """
        Add an edge from u to v.
        
        Mathematical: Set A[u][v] = weight
        For undirected graphs, also set A[v][u] = weight
        
        Args:
            u: Source vertex (0 to n-1)
            v: Destination vertex (0 to n-1)
            weight: Edge weight (default 1 for unweighted graphs)
        """
        self.matrix[u][v] = weight
        if not self.directed:
            self.matrix[v][u] = weight
    
    def has_edge(self, u, v):
        """
        Check if there's an edge from u to v.
        
        Mathematical: Check if A[u][v] ≠ 0
        """
        return self.matrix[u][v] != 0
    
    def get_neighbors(self, v):
        """
        Get all neighbors of vertex v.
        
        Mathematical: Return {u : A[v][u] ≠ 0}
        """
        neighbors = []
        for u in range(self.n):
            if self.matrix[v][u] != 0:
                neighbors.append((u, self.matrix[v][u]))
        return neighbors
    
    def __repr__(self):
        """String representation showing the matrix."""
        lines = [f"GraphMatrix(n={self.n}, directed={self.directed})"]
        lines.append("Matrix:")
        for row in self.matrix:
            lines.append("  " + str(row))
        return "\n".join(lines)

# Example: Create a weighted directed graph
g = GraphMatrix(4, directed=True)
g.add_edge(0, 1, 5)  # Edge from 0 to 1 with weight 5
g.add_edge(1, 2, 3)
g.add_edge(2, 3, 2)
g.add_edge(0, 3, 10)

print(g)
# Output:
# GraphMatrix(n=4, directed=True)
# Matrix:
#   [0, 5, 0, 10]
#   [0, 0, 3, 0]
#   [0, 0, 0, 2]
#   [0, 0, 0, 0]
```

## Comparing Representations

| Operation | Adjacency List | Adjacency Matrix |
|-----------|----------------|------------------|
| Space | $O(V + E)$ | $O(V^2)$ |
| Add edge | $O(1)$ | $O(1)$ |
| Check if edge exists | $O(\text{deg}(v))$ | $O(1)$ |
| Get all neighbors | $O(\text{deg}(v))$ | $O(V)$ |
| Best for | Sparse graphs | Dense graphs |

**Rule of thumb:** Use adjacency list unless you need $O(1)$ edge lookups or the graph is very dense.

## Basic Graph Traversals

### Depth-First Search (DFS)

Explore as far as possible along each branch before backtracking.

**Mathematical intuition:** Recursively visit all vertices reachable from a starting vertex.

```python
def dfs(graph, start, visited=None):
    """
    Depth-first search traversal.
    
    Args:
        graph: Graph object with get_neighbors method
        start: Starting vertex
        visited: Set of already visited vertices
    
    Returns:
        List of vertices in DFS order
    """
    if visited is None:
        visited = set()
    
    result = []
    
    def dfs_helper(v):
        visited.add(v)
        result.append(v)
        
        for neighbor in graph.get_neighbors(v):
            # Handle weighted graphs (neighbor might be tuple)
            next_v = neighbor[0] if isinstance(neighbor, tuple) else neighbor
            if next_v not in visited:
                dfs_helper(next_v)
    
    dfs_helper(start)
    return result

# Example
g = Graph()
g.add_edge(0, 1)
g.add_edge(0, 2)
g.add_edge(1, 3)
g.add_edge(2, 3)

print(dfs(g, 0))  # [0, 1, 3, 2] (order may vary)
```

### Breadth-First Search (BFS)

Explore all neighbors at the current depth before moving to the next level.

**Mathematical intuition:** Visit vertices in order of their distance from the start.

```python
from collections import deque

def bfs(graph, start):
    """
    Breadth-first search traversal.
    
    Args:
        graph: Graph object with get_neighbors method
        start: Starting vertex
    
    Returns:
        List of vertices in BFS order
    """
    visited = {start}
    queue = deque([start])
    result = []
    
    while queue:
        v = queue.popleft()
        result.append(v)
        
        for neighbor in graph.get_neighbors(v):
            # Handle weighted graphs
            next_v = neighbor[0] if isinstance(neighbor, tuple) else neighbor
            if next_v not in visited:
                visited.add(next_v)
                queue.append(next_v)
    
    return result

# Example
print(bfs(g, 0))  # [0, 1, 2, 3]
```

## Conclusion

Graphs are a bridge between abstract mathematics and practical programming. Understanding the mathematical foundation—vertices, edges, paths, and properties—gives us the vocabulary and intuition to solve complex problems.

The key takeaways:
1. **Graphs model relationships** between entities
2. **Directed vs undirected** determines whether relationships are mutual
3. **Adjacency lists** are best for sparse graphs, **matrices** for dense graphs
4. **DFS and BFS** are the fundamental traversal algorithms

With this foundation, you're ready to tackle more advanced graph algorithms like shortest paths, minimum spanning trees, and network flow. To learn how to identify when a problem can be solved with graphs, check out [Recognizing Graph Problems: A Pattern Recognition Guide](/2025/11/22/recognizing-graph-problems).
