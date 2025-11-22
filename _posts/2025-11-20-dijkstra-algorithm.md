---
layout: post
title: "Dijkstra's Algorithm: Finding the Shortest Path"
date: 2025-11-20
categories: algorithms graphs
---

Dijkstra's algorithm is one of the most famous algorithms in computer science. It solves the single-source shortest path problem: given a weighted graph and a starting vertex, find the shortest path to every other vertex.

Unlike breadth-first search (BFS), which only works for unweighted graphs, Dijkstra's handles weighted edges. Unlike the [Floyd-Warshall algorithm](/2025/11/21/floyd-warshall-algorithm), which finds all-pairs shortest paths, Dijkstra's focuses on paths from a single source—making it much faster for that specific use case.

## The Problem

**Input:** 
- A weighted graph $G = (V, E)$ with non-negative edge weights
- A source vertex $s$

**Output:** 
- The shortest distance from $s$ to every other vertex
- Optionally, the actual shortest paths

**Key constraint:** Edge weights must be non-negative. For graphs with negative weights, use Bellman-Ford instead.

## The Greedy Insight

Dijkstra's algorithm is a greedy algorithm. The key insight is:

> Once we've found the shortest path to a vertex, we never need to reconsider it.

The algorithm maintains two sets:
1. **Visited**: Vertices whose shortest distance from source is finalized
2. **Unvisited**: Vertices we haven't finalized yet

At each step, we pick the unvisited vertex with the smallest tentative distance, finalize it, and update its neighbors.

## The Algorithm

```python
import heapq
from collections import defaultdict

def dijkstra(graph, start):
    """
    Find shortest paths from start to all other vertices.
    
    Args:
        graph: Dictionary mapping vertex -> list of (neighbor, weight) tuples
        start: Starting vertex
    
    Returns:
        Dictionary mapping vertex -> shortest distance from start
    """
    # Initialize distances to infinity
    distances = {vertex: float('inf') for vertex in graph}
    distances[start] = 0
    
    # Priority queue: (distance, vertex)
    pq = [(0, start)]
    visited = set()
    
    while pq:
        current_dist, current = heapq.heappop(pq)
        
        # Skip if already visited
        if current in visited:
            continue
        
        visited.add(current)
        
        # Update neighbors
        for neighbor, weight in graph[current]:
            distance = current_dist + weight
            
            # If we found a shorter path, update it
            if distance < distances[neighbor]:
                distances[neighbor] = distance
                heapq.heappush(pq, (distance, neighbor))
    
    return distances
```

## Step-by-Step Example

Consider this graph:

```
      7        9
  A -----> B -----> C
  |        |        |
  |14      |10      |2
  |        |        |
  v        v        v
  D -----> E -----> F
      9        11
```

Let's find shortest paths from **A**.

**Initial state:**
```
distances = {A: 0, B: ∞, C: ∞, D: ∞, E: ∞, F: ∞}
pq = [(0, A)]
visited = {}
```

**Step 1: Process A (distance 0)**
- Visit A
- Update neighbors: B (0+7=7), D (0+14=14)
```
distances = {A: 0, B: 7, C: ∞, D: 14, E: ∞, F: ∞}
pq = [(7, B), (14, D)]
visited = {A}
```

**Step 2: Process B (distance 7)**
- Visit B
- Update neighbors: C (7+9=16), E (7+10=17)
```
distances = {A: 0, B: 7, C: 16, D: 14, E: 17, F: ∞}
pq = [(14, D), (16, C), (17, E)]
visited = {A, B}
```

**Step 3: Process D (distance 14)**
- Visit D
- Update neighbors: E (14+9=23) — worse than current 17, skip
```
distances = {A: 0, B: 7, C: 16, D: 14, E: 17, F: ∞}
pq = [(16, C), (17, E)]
visited = {A, B, D}
```

**Step 4: Process C (distance 16)**
- Visit C
- Update neighbors: F (16+2=18)
```
distances = {A: 0, B: 7, C: 16, D: 14, E: 17, F: 18}
pq = [(17, E), (18, F)]
visited = {A, B, D, C}
```

**Step 5: Process E (distance 17)**
- Visit E
- Update neighbors: F (17+11=28) — worse than current 18, skip
```
distances = {A: 0, B: 7, C: 16, D: 14, E: 17, F: 18}
pq = [(18, F)]
visited = {A, B, D, C, E}
```

**Step 6: Process F (distance 18)**
- Visit F (no neighbors)
- Done!

**Final distances from A:**
```
A: 0, B: 7, C: 16, D: 14, E: 17, F: 18
```

## Path Reconstruction

To recover the actual paths, we track which vertex led to each shortest distance:

```python
def dijkstra_with_path(graph, start):
    """
    Find shortest paths and reconstruct them.
    
    Returns:
        (distances, previous) where previous[v] is the vertex before v in shortest path
    """
    distances = {vertex: float('inf') for vertex in graph}
    distances[start] = 0
    previous = {vertex: None for vertex in graph}
    
    pq = [(0, start)]
    visited = set()
    
    while pq:
        current_dist, current = heapq.heappop(pq)
        
        if current in visited:
            continue
        
        visited.add(current)
        
        for neighbor, weight in graph[current]:
            distance = current_dist + weight
            
            if distance < distances[neighbor]:
                distances[neighbor] = distance
                previous[neighbor] = current
                heapq.heappush(pq, (distance, neighbor))
    
    return distances, previous

def reconstruct_path(previous, start, end):
    """Build the path from start to end."""
    path = []
    current = end
    
    while current is not None:
        path.append(current)
        current = previous[current]
    
    path.reverse()
    
    # Check if path is valid
    if path[0] != start:
        return []  # No path exists
    
    return path

# Example usage
graph = {
    'A': [('B', 7), ('D', 14)],
    'B': [('C', 9), ('E', 10)],
    'C': [('F', 2)],
    'D': [('E', 9)],
    'E': [('F', 11)],
    'F': []
}

distances, previous = dijkstra_with_path(graph, 'A')
path = reconstruct_path(previous, 'A', 'F')
print(f"Shortest path from A to F: {' -> '.join(path)}")  # A -> B -> C -> F
print(f"Distance: {distances['F']}")  # 18
```

## Why the Priority Queue?

The priority queue (min-heap) is crucial for efficiency. We always process the vertex with the smallest tentative distance next. This ensures we finalize vertices in order of their actual shortest distance from the source.

Without a priority queue, we'd need to scan all unvisited vertices each time to find the minimum—making the algorithm $O(V^2)$ instead of $O((V + E) \log V)$.

## Complexity Analysis

**Time Complexity:** $O((V + E) \log V)$ with a binary heap
- Each vertex is added to the heap once: $O(V \log V)$
- Each edge is relaxed at most once: $O(E \log V)$
- Total: $O((V + E) \log V)$

**Space Complexity:** $O(V)$ for the distances, previous, and priority queue.

**With Fibonacci heap:** Time complexity improves to $O(E + V \log V)$, but the constant factors make it impractical for most real-world use cases.

## Common Pitfalls

### 1. Negative Edge Weights
Dijkstra's **does not work** with negative edge weights. Consider:

```
A --(-5)--> B --(3)--> C
A --------(1)--------> C
```

Dijkstra would finalize C with distance 1, but the path A→B→C has distance -2.

**Solution:** Use Bellman-Ford for graphs with negative weights.

### 2. Not Checking if Already Visited
```python
# WRONG: Process vertex multiple times
while pq:
    current_dist, current = heapq.heappop(pq)
    # Missing: if current in visited: continue
```

This leads to redundant work and incorrect results.

### 3. Using Wrong Data Structure
```python
# WRONG: Using a list instead of heap
pq = []
pq.append((distance, vertex))
pq.sort()  # O(n log n) every time!
```

Always use `heapq` for the priority queue.

## Dijkstra vs Other Algorithms

| Algorithm | Use Case | Time Complexity | Negative Weights? |
|-----------|----------|-----------------|-------------------|
| BFS | Unweighted, single-source | $O(V + E)$ | N/A |
| Dijkstra | Weighted, single-source | $O((V+E) \log V)$ | No |
| Bellman-Ford | Weighted, single-source | $O(VE)$ | Yes |
| Floyd-Warshall | All-pairs | $O(V^3)$ | Yes |

## Real-World Applications

1. **GPS Navigation:** Finding the fastest route from your location to a destination.
2. **Network Routing:** OSPF (Open Shortest Path First) protocol uses Dijkstra's.
3. **Social Networks:** Finding degrees of separation with weighted connections.
4. **Game AI:** Pathfinding for NPCs with terrain costs.

## Conclusion

Dijkstra's algorithm is a cornerstone of graph algorithms. Its greedy approach—always picking the closest unvisited vertex—guarantees optimal shortest paths for graphs with non-negative weights.

The key to understanding Dijkstra's is recognizing that once we finalize a vertex's distance, we never need to reconsider it. This property, combined with a priority queue for efficiency, makes it one of the most elegant and practical algorithms in computer science.
