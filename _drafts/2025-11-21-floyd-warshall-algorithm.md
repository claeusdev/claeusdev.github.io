---
layout: post
title: "Floyd-Warshall Algorithm: All-Pairs Shortest Paths"
date: 2025-11-21
categories: algorithms graphs
---

When you need to find the shortest path between every pair of vertices in a graph, the Floyd-Warshall algorithm is your go-to solution. Unlike [Dijkstra's algorithm](/2025/11/20/dijkstra-algorithm), which finds shortest paths from a single source, Floyd-Warshall computes shortest paths between **all pairs** of vertices in one elegant sweep.

## The Problem

Given a weighted graph (directed or undirected), find the shortest distance between every pair of vertices. The graph may contain negative edge weights, but no negative cycles.

**Input:** A graph with $n$ vertices represented as an adjacency matrix where `dist[i][j]` is the weight of the edge from vertex $i$ to vertex $j$. If there's no edge, use infinity ($\infty$).

**Output:** A matrix where `dist[i][j]` contains the shortest distance from vertex $i$ to vertex $j$.

## The Core Insight

The algorithm is based on a beautiful observation: the shortest path from $i$ to $j$ either:
1. Doesn't go through any intermediate vertex, or
2. Goes through some intermediate vertex $k$

If we consider vertices one by one as potential intermediate vertices, we can build up the solution incrementally.

**Key idea:** For each vertex $k$, update all pairs $(i, j)$ by checking if going through $k$ gives a shorter path:

$$\text{dist}[i][j] = \min(\text{dist}[i][j], \text{dist}[i][k] + \text{dist}[k][j])$$

## The Algorithm

```python
def floyd_warshall(graph):
    """
    Find shortest paths between all pairs of vertices.
    
    Args:
        graph: 2D list where graph[i][j] is the weight from i to j.
               Use float('inf') for no edge.
    
    Returns:
        2D list of shortest distances between all pairs.
    """
    n = len(graph)
    # Initialize distance matrix with a copy of the graph
    dist = [row[:] for row in graph]
    
    # Consider each vertex as an intermediate point
    for k in range(n):
        # For each pair of vertices
        for i in range(n):
            for j in range(n):
                # Update distance if path through k is shorter
                if dist[i][k] + dist[k][j] < dist[i][j]:
                    dist[i][j] = dist[i][k] + dist[k][j]
    
    return dist
```

## Step-by-Step Example

Let's trace through a small example. Consider this graph:

```
    1
  /   \
 5     2
0       2
 \     /
  3   1
    \ /
     3
```

**Adjacency matrix:**
```
     0    1    2    3
0 [  0,   5, inf,   3 ]
1 [  5,   0,   2, inf ]
2 [ inf,  2,   0,   1 ]
3 [  3, inf,   1,   0 ]
```

### Iteration k=0 (considering vertex 0 as intermediate)

Check all pairs to see if going through vertex 0 improves the path:
- `dist[1][3]`: Direct = $\infty$, via 0 = $5 + 3 = 8$ → Update to 8
- `dist[3][1]`: Direct = $\infty$, via 0 = $3 + 5 = 8$ → Update to 8

### Iteration k=1 (considering vertex 1)

- `dist[0][2]`: Direct = $\infty$, via 1 = $5 + 2 = 7$ → Update to 7
- `dist[2][0]`: Direct = $\infty$, via 1 = $2 + 5 = 7$ → Update to 7

### Iteration k=2 (considering vertex 2)

- `dist[1][3]`: Current = 8, via 2 = $2 + 1 = 3$ → Update to 3
- `dist[0][3]`: Current = 3, via 2 = $7 + 1 = 8$ → Keep 3

### Iteration k=3 (considering vertex 3)

- `dist[0][2]`: Current = 7, via 3 = $3 + 1 = 4$ → Update to 4
- `dist[2][0]`: Current = 7, via 3 = $1 + 3 = 4$ → Update to 4

**Final result:**
```
     0    1    2    3
0 [  0,   5,   4,   3 ]
1 [  5,   0,   2,   3 ]
2 [  4,   2,   0,   1 ]
3 [  3,   3,   1,   0 ]
```

## Path Reconstruction

The basic algorithm only gives us distances. To reconstruct the actual paths, we need to track which intermediate vertex gave us the best path:

```python
def floyd_warshall_with_path(graph):
    n = len(graph)
    dist = [row[:] for row in graph]
    # next[i][j] stores the next vertex on the shortest path from i to j
    next_vertex = [[j if graph[i][j] != float('inf') else None 
                    for j in range(n)] for i in range(n)]
    
    for k in range(n):
        for i in range(n):
            for j in range(n):
                if dist[i][k] + dist[k][j] < dist[i][j]:
                    dist[i][j] = dist[i][k] + dist[k][j]
                    next_vertex[i][j] = next_vertex[i][k]
    
    return dist, next_vertex

def reconstruct_path(next_vertex, start, end):
    """Reconstruct the shortest path from start to end."""
    if next_vertex[start][end] is None:
        return []
    
    path = [start]
    while start != end:
        start = next_vertex[start][end]
        path.append(start)
    return path

# Example usage
graph = [
    [0, 5, float('inf'), 3],
    [5, 0, 2, float('inf')],
    [float('inf'), 2, 0, 1],
    [3, float('inf'), 1, 0]
]

dist, next_v = floyd_warshall_with_path(graph)
path = reconstruct_path(next_v, 0, 2)
print(f"Shortest path from 0 to 2: {path}")  # [0, 3, 2]
print(f"Distance: {dist[0][2]}")  # 4
```

## Detecting Negative Cycles

A negative cycle is a cycle whose total weight is negative. If such a cycle exists, there's no shortest path (you can keep going around the cycle to get arbitrarily small distances).

Floyd-Warshall can detect negative cycles by checking the diagonal after the algorithm completes:

```python
def has_negative_cycle(dist):
    """Check if the graph contains a negative cycle."""
    n = len(dist)
    for i in range(n):
        if dist[i][i] < 0:
            return True
    return False
```

If `dist[i][i] < 0` for any vertex $i$, there's a negative cycle reachable from $i$.

## Complexity Analysis

**Time Complexity:** $O(V^3)$ where $V$ is the number of vertices.
- Three nested loops, each running $V$ times.

**Space Complexity:** $O(V^2)$ for the distance matrix.

## When to Use Floyd-Warshall

**Use Floyd-Warshall when:**
- You need shortest paths between **all pairs** of vertices
- The graph is **dense** (many edges)
- The graph may have **negative edge weights** (but no negative cycles)
- $V$ is relatively small (< 400-500 vertices)

**Don't use Floyd-Warshall when:**
- You only need shortest paths from a single source → Use Dijkstra or Bellman-Ford
- The graph is very large → $O(V^3)$ becomes prohibitive
- You have a sparse graph and need all-pairs → Run Dijkstra from each vertex instead

## Comparison with Other Algorithms

| Algorithm | Use Case | Time Complexity | Negative Weights? |
|-----------|----------|-----------------|-------------------|
| Dijkstra | Single-source | $O((V+E) \log V)$ | No |
| Bellman-Ford | Single-source | $O(VE)$ | Yes |
| Floyd-Warshall | All-pairs | $O(V^3)$ | Yes |

## Real-World Applications

1. **Network Routing:** Finding optimal routes between all pairs of routers in a network.
2. **Game Development:** Precomputing distances between all locations in a game map.
3. **Transitive Closure:** Determining reachability between all pairs of nodes.
4. **Graph Analysis:** Finding the graph's diameter (maximum shortest path).

## Conclusion

Floyd-Warshall is a classic dynamic programming algorithm that elegantly solves the all-pairs shortest path problem. Its simplicity (just three nested loops!) belies its power. While it's not the fastest for sparse graphs, it's unbeatable for dense graphs where you need all-pairs distances, and it handles negative weights gracefully.

The key insight—incrementally considering each vertex as a potential intermediate point—is a beautiful example of how breaking a problem into subproblems can lead to an efficient solution.
