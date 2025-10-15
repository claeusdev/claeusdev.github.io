# Modern C++ Memory Management: A Comprehensive Tutorial

## Table of Contents
1. [Introduction](#introduction)
2. [RAII: The Foundation of Modern C++ Memory Management](#raii-the-foundation-of-modern-c-memory-management)
3. [Smart Pointers](#smart-pointers)
4. [Move Semantics and Resource Management](#move-semantics-and-resource-management)
5. [Containers and Memory Management](#containers-and-memory-management)
6. [Custom Memory Management](#custom-memory-management)
7. [Memory Pools and Custom Allocators](#memory-pools-and-custom-allocators)
8. [Best Practices and Common Pitfalls](#best-practices-and-common-pitfalls)
9. [Performance Considerations](#performance-considerations)
10. [Exercises](#exercises)
11. [Further Reading](#further-reading)

## Introduction

Memory management is one of the most critical aspects of C++ programming. While C++ gives you fine-grained control over memory, it also requires careful attention to avoid memory leaks, dangling pointers, and other memory-related bugs. Modern C++ (C++11 and later) provides powerful tools and idioms that make memory management safer and more efficient.

This tutorial will guide you through modern C++ memory management techniques, from basic concepts to advanced patterns. By the end, you'll understand how to write memory-safe, efficient C++ code using modern practices.

### Key Learning Objectives
- Understand RAII (Resource Acquisition Is Initialization) principles
- Master smart pointers and their appropriate usage
- Learn move semantics for efficient resource transfer
- Explore modern container usage patterns
- Understand custom memory management techniques
- Recognize and avoid common memory management pitfalls

## RAII: The Foundation of Modern C++ Memory Management

RAII (Resource Acquisition Is Initialization) is the cornerstone of modern C++ memory management. The principle states that resources should be acquired during object construction and released during object destruction.

### The Problem with Manual Memory Management

```cpp
// BAD: Manual memory management - error-prone
void problematicFunction() {
    int* ptr = new int(42);
    // ... some code that might throw an exception
    delete ptr;  // What if an exception is thrown before this line?
}
```

### The RAII Solution

```cpp
// GOOD: RAII approach
class IntWrapper {
private:
    int* ptr;
    
public:
    IntWrapper(int value) : ptr(new int(value)) {}
    
    ~IntWrapper() {
        delete ptr;  // Automatically called when object goes out of scope
    }
    
    int getValue() const { return *ptr; }
    void setValue(int value) { *ptr = value; }
    
    // Disable copy to prevent double deletion
    IntWrapper(const IntWrapper&) = delete;
    IntWrapper& operator=(const IntWrapper&) = delete;
};

void safeFunction() {
    IntWrapper wrapper(42);
    // ... some code that might throw an exception
    // wrapper's destructor is automatically called, even if an exception occurs
}
```

### RAII Benefits
- **Automatic cleanup**: Resources are automatically released when objects go out of scope
- **Exception safety**: Destructors are called even when exceptions occur
- **Clear ownership**: Object lifetime is tied to scope
- **Reduced bugs**: No manual memory management means fewer opportunities for errors

## Smart Pointers

Smart pointers are objects that behave like pointers but provide automatic memory management. They are the primary tool for memory management in modern C++.

### std::unique_ptr

`std::unique_ptr` represents exclusive ownership of a dynamically allocated object.

```cpp
#include <memory>
#include <iostream>

void uniquePtrExample() {
    // Creating a unique_ptr
    std::unique_ptr<int> ptr1 = std::make_unique<int>(42);
    
    // Accessing the value
    std::cout << "Value: " << *ptr1 << std::endl;
    
    // Moving ownership
    std::unique_ptr<int> ptr2 = std::move(ptr1);
    
    // ptr1 is now nullptr, ptr2 owns the object
    if (ptr1 == nullptr) {
        std::cout << "ptr1 is now empty" << std::endl;
    }
    
    // Automatic cleanup when ptr2 goes out of scope
}

// Custom deleter example
void customDeleter(int* ptr) {
    std::cout << "Custom deleter called" << std::endl;
    delete ptr;
}

void customDeleterExample() {
    std::unique_ptr<int, decltype(&customDeleter)> ptr(new int(100), customDeleter);
    // Custom deleter will be called when ptr goes out of scope
}
```

### std::shared_ptr

`std::shared_ptr` enables shared ownership of an object through reference counting.

```cpp
#include <memory>
#include <iostream>

void sharedPtrExample() {
    // Creating a shared_ptr
    std::shared_ptr<int> ptr1 = std::make_shared<int>(42);
    
    // Creating another shared_ptr pointing to the same object
    std::shared_ptr<int> ptr2 = ptr1;
    
    std::cout << "Reference count: " << ptr1.use_count() << std::endl; // 2
    
    // Both pointers can access the same object
    std::cout << "Value via ptr1: " << *ptr1 << std::endl;
    std::cout << "Value via ptr2: " << *ptr2 << std::endl;
    
    // When both go out of scope, the object is automatically deleted
}

// Circular reference problem and solution
class Node {
public:
    std::string name;
    std::shared_ptr<Node> parent;
    std::shared_ptr<Node> child;
    
    Node(const std::string& n) : name(n) {}
    
    ~Node() {
        std::cout << "Node " << name << " destroyed" << std::endl;
    }
};

void circularReferenceExample() {
    // This creates a circular reference - memory leak!
    auto parent = std::make_shared<Node>("parent");
    auto child = std::make_shared<Node>("child");
    
    parent->child = child;
    child->parent = parent;  // Circular reference!
    
    // Objects won't be destroyed due to circular reference
}

// Solution: Use weak_ptr to break circular references
class SafeNode {
public:
    std::string name;
    std::weak_ptr<SafeNode> parent;  // Use weak_ptr
    std::shared_ptr<SafeNode> child;
    
    SafeNode(const std::string& n) : name(n) {}
    
    ~SafeNode() {
        std::cout << "SafeNode " << name << " destroyed" << std::endl;
    }
};
```

### std::weak_ptr

`std::weak_ptr` provides non-owning access to an object managed by `std::shared_ptr`.

```cpp
void weakPtrExample() {
    std::shared_ptr<int> shared = std::make_shared<int>(42);
    std::weak_ptr<int> weak = shared;
    
    // Check if object still exists
    if (auto locked = weak.lock()) {
        std::cout << "Object exists, value: " << *locked << std::endl;
    } else {
        std::cout << "Object has been destroyed" << std::endl;
    }
    
    // Reset shared_ptr
    shared.reset();
    
    // Now weak_ptr is expired
    if (weak.expired()) {
        std::cout << "Object has been destroyed" << std::endl;
    }
}
```

### When to Use Each Smart Pointer

| Smart Pointer | Use When | Key Characteristics |
|---------------|----------|-------------------|
| `std::unique_ptr` | Single ownership | Fast, no overhead, non-copyable |
| `std::shared_ptr` | Shared ownership | Reference counting, copyable, slight overhead |
| `std::weak_ptr` | Non-owning access | Break circular references, check if object exists |

## Move Semantics and Resource Management

Move semantics (introduced in C++11) allow efficient transfer of resources without copying.

### Understanding Move Semantics

```cpp
#include <iostream>
#include <string>

class Resource {
private:
    int* data;
    size_t size;
    
public:
    // Constructor
    Resource(size_t s) : size(s), data(new int[s]) {
        std::cout << "Resource created with size " << s << std::endl;
    }
    
    // Destructor
    ~Resource() {
        delete[] data;
        std::cout << "Resource destroyed" << std::endl;
    }
    
    // Copy constructor (expensive)
    Resource(const Resource& other) : size(other.size), data(new int[other.size]) {
        std::copy(other.data, other.data + size, data);
        std::cout << "Resource copied" << std::endl;
    }
    
    // Copy assignment
    Resource& operator=(const Resource& other) {
        if (this != &other) {
            delete[] data;
            size = other.size;
            data = new int[size];
            std::copy(other.data, other.data + size, data);
            std::cout << "Resource copy assigned" << std::endl;
        }
        return *this;
    }
    
    // Move constructor (cheap)
    Resource(Resource&& other) noexcept : size(other.size), data(other.data) {
        other.data = nullptr;
        other.size = 0;
        std::cout << "Resource moved" << std::endl;
    }
    
    // Move assignment
    Resource& operator=(Resource&& other) noexcept {
        if (this != &other) {
            delete[] data;
            size = other.size;
            data = other.data;
            other.data = nullptr;
            other.size = 0;
            std::cout << "Resource move assigned" << std::endl;
        }
        return *this;
    }
    
    int& operator[](size_t index) { return data[index]; }
    const int& operator[](size_t index) const { return data[index]; }
    size_t getSize() const { return size; }
};

void moveSemanticsExample() {
    Resource r1(1000);
    r1[0] = 42;
    
    // Move construction - efficient!
    Resource r2 = std::move(r1);
    
    // r1 is now in a valid but unspecified state
    // r2 owns the original data
    
    std::cout << "r2[0] = " << r2[0] << std::endl;
}
```

### Perfect Forwarding

```cpp
#include <utility>

template<typename T>
class Wrapper {
private:
    T value;
    
public:
    // Perfect forwarding constructor
    template<typename U>
    Wrapper(U&& u) : value(std::forward<U>(u)) {}
    
    const T& get() const { return value; }
};

void perfectForwardingExample() {
    std::string s = "Hello";
    
    // Forward lvalue
    Wrapper<std::string> w1(s);
    
    // Forward rvalue
    Wrapper<std::string> w2(std::string("World"));
    
    // Forward temporary
    Wrapper<std::string> w3("Temporary");
}
```

## Containers and Memory Management

Modern C++ containers handle memory management automatically and efficiently.

### std::vector: Dynamic Arrays

```cpp
#include <vector>
#include <iostream>

void vectorExample() {
    // Creating vectors
    std::vector<int> vec1;                    // Empty vector
    std::vector<int> vec2(10, 5);             // 10 elements, all set to 5
    std::vector<int> vec3{1, 2, 3, 4, 5};    // Initializer list
    
    // Adding elements
    vec1.push_back(10);
    vec1.emplace_back(20);  // More efficient for complex types
    
    // Accessing elements
    std::cout << "First element: " << vec1[0] << std::endl;
    std::cout << "Size: " << vec1.size() << std::endl;
    std::cout << "Capacity: " << vec1.capacity() << std::endl;
    
    // Reserve space to avoid reallocations
    vec1.reserve(100);
    
    // Range-based for loop
    for (const auto& element : vec3) {
        std::cout << element << " ";
    }
    std::cout << std::endl;
}

// Custom allocator example
#include <memory>

template<typename T>
class CustomAllocator {
public:
    using value_type = T;
    
    T* allocate(std::size_t n) {
        std::cout << "Allocating " << n << " elements" << std::endl;
        return static_cast<T*>(::operator new(n * sizeof(T)));
    }
    
    void deallocate(T* p, std::size_t n) {
        std::cout << "Deallocating " << n << " elements" << std::endl;
        ::operator delete(p);
    }
    
    template<typename U>
    bool operator==(const CustomAllocator<U>&) const { return true; }
    
    template<typename U>
    bool operator!=(const CustomAllocator<U>&) const { return false; }
};

void customAllocatorExample() {
    std::vector<int, CustomAllocator<int>> vec;
    vec.push_back(1);
    vec.push_back(2);
    vec.push_back(3);
}
```

### std::array: Fixed-Size Arrays

```cpp
#include <array>
#include <algorithm>

void arrayExample() {
    std::array<int, 5> arr = {1, 2, 3, 4, 5};
    
    // STL algorithms work with arrays
    std::sort(arr.begin(), arr.end());
    
    // Range-based for loop
    for (const auto& element : arr) {
        std::cout << element << " ";
    }
    std::cout << std::endl;
    
    // Size is known at compile time
    std::cout << "Array size: " << arr.size() << std::endl;
}
```

### Modern Container Usage Patterns

```cpp
#include <vector>
#include <string>
#include <algorithm>

class Person {
public:
    std::string name;
    int age;
    
    Person(const std::string& n, int a) : name(n), age(a) {}
    
    // Move constructor for efficiency
    Person(Person&& other) noexcept 
        : name(std::move(other.name)), age(other.age) {}
};

void modernContainerPatterns() {
    std::vector<Person> people;
    
    // Reserve space to avoid reallocations
    people.reserve(1000);
    
    // Emplace back for efficiency (constructs in place)
    people.emplace_back("Alice", 30);
    people.emplace_back("Bob", 25);
    people.emplace_back("Charlie", 35);
    
    // Use algorithms instead of manual loops
    auto it = std::find_if(people.begin(), people.end(),
        [](const Person& p) { return p.age > 30; });
    
    if (it != people.end()) {
        std::cout << "Found person over 30: " << it->name << std::endl;
    }
    
    // Sort by age
    std::sort(people.begin(), people.end(),
        [](const Person& a, const Person& b) { return a.age < b.age; });
}
```

## Custom Memory Management

Sometimes you need more control over memory allocation than standard containers provide.

### Custom Memory Allocators

```cpp
#include <memory>
#include <iostream>

class PoolAllocator {
private:
    char* pool;
    size_t poolSize;
    size_t currentOffset;
    
public:
    PoolAllocator(size_t size) : poolSize(size), currentOffset(0) {
        pool = static_cast<char*>(std::aligned_alloc(alignof(std::max_align_t), size));
        if (!pool) {
            throw std::bad_alloc();
        }
    }
    
    ~PoolAllocator() {
        std::free(pool);
    }
    
    // Non-copyable
    PoolAllocator(const PoolAllocator&) = delete;
    PoolAllocator& operator=(const PoolAllocator&) = delete;
    
    template<typename T>
    T* allocate(size_t n = 1) {
        size_t size = sizeof(T) * n;
        size_t alignment = alignof(T);
        
        // Align the current offset
        size_t alignedOffset = (currentOffset + alignment - 1) & ~(alignment - 1);
        
        if (alignedOffset + size > poolSize) {
            throw std::bad_alloc();
        }
        
        T* result = reinterpret_cast<T*>(pool + alignedOffset);
        currentOffset = alignedOffset + size;
        return result;
    }
    
    void reset() {
        currentOffset = 0;
    }
};

void poolAllocatorExample() {
    PoolAllocator pool(1024);
    
    // Allocate some integers
    int* ints = pool.allocate<int>(10);
    for (int i = 0; i < 10; ++i) {
        ints[i] = i * i;
    }
    
    // Allocate some doubles
    double* doubles = pool.allocate<double>(5);
    for (int i = 0; i < 5; ++i) {
        doubles[i] = i * 3.14;
    }
    
    // Use the allocated memory
    for (int i = 0; i < 10; ++i) {
        std::cout << "ints[" << i << "] = " << ints[i] << std::endl;
    }
    
    // Pool is automatically cleaned up when pool goes out of scope
}
```

### Memory-Mapped Files

```cpp
#include <fstream>
#include <iostream>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

class MemoryMappedFile {
private:
    void* data;
    size_t size;
    int fd;
    
public:
    MemoryMappedFile(const std::string& filename) : data(nullptr), size(0), fd(-1) {
        fd = open(filename.c_str(), O_RDONLY);
        if (fd == -1) {
            throw std::runtime_error("Failed to open file");
        }
        
        struct stat st;
        if (fstat(fd, &st) == -1) {
            close(fd);
            throw std::runtime_error("Failed to get file size");
        }
        
        size = st.st_size;
        data = mmap(nullptr, size, PROT_READ, MAP_PRIVATE, fd, 0);
        
        if (data == MAP_FAILED) {
            close(fd);
            throw std::runtime_error("Failed to map file");
        }
    }
    
    ~MemoryMappedFile() {
        if (data != MAP_FAILED) {
            munmap(data, size);
        }
        if (fd != -1) {
            close(fd);
        }
    }
    
    // Non-copyable
    MemoryMappedFile(const MemoryMappedFile&) = delete;
    MemoryMappedFile& operator=(const MemoryMappedFile&) = delete;
    
    const char* getData() const { return static_cast<const char*>(data); }
    size_t getSize() const { return size; }
};

void memoryMappedFileExample() {
    try {
        MemoryMappedFile file("example.txt");
        
        std::cout << "File size: " << file.getSize() << " bytes" << std::endl;
        
        // Access file content as if it were in memory
        const char* content = file.getData();
        for (size_t i = 0; i < std::min(file.getSize(), size_t(100)); ++i) {
            std::cout << content[i];
        }
        std::cout << std::endl;
        
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
    }
}
```

## Memory Pools and Custom Allocators

### Object Pool Pattern

```cpp
#include <memory>
#include <vector>
#include <queue>

template<typename T>
class ObjectPool {
private:
    std::queue<std::unique_ptr<T>> available;
    std::vector<std::unique_ptr<T>> allObjects;
    
public:
    ObjectPool() = default;
    
    // Non-copyable
    ObjectPool(const ObjectPool&) = delete;
    ObjectPool& operator=(const ObjectPool&) = delete;
    
    // Get an object from the pool
    std::unique_ptr<T> acquire() {
        if (available.empty()) {
            // Create a new object
            auto obj = std::make_unique<T>();
            allObjects.push_back(std::move(obj));
            return std::make_unique<T>();
        }
        
        auto obj = std::move(available.front());
        available.pop();
        return obj;
    }
    
    // Return an object to the pool
    void release(std::unique_ptr<T> obj) {
        if (obj) {
            available.push(std::move(obj));
        }
    }
    
    size_t size() const { return allObjects.size(); }
    size_t availableCount() const { return available.size(); }
};

class ExpensiveObject {
public:
    ExpensiveObject() {
        // Simulate expensive construction
        data.resize(1000, 0);
    }
    
    void reset() {
        data.clear();
        data.resize(1000, 0);
    }
    
private:
    std::vector<int> data;
};

void objectPoolExample() {
    ObjectPool<ExpensiveObject> pool;
    
    // Acquire objects from the pool
    auto obj1 = pool.acquire();
    auto obj2 = pool.acquire();
    
    std::cout << "Pool size: " << pool.size() << std::endl;
    std::cout << "Available: " << pool.availableCount() << std::endl;
    
    // Return objects to the pool
    pool.release(std::move(obj1));
    pool.release(std::move(obj2));
    
    std::cout << "After release - Available: " << pool.availableCount() << std::endl;
}
```

## Best Practices and Common Pitfalls

### Best Practices

1. **Prefer RAII over manual memory management**
```cpp
// BAD
void badExample() {
    int* ptr = new int(42);
    // ... code ...
    delete ptr;  // Easy to forget or miss in exception paths
}

// GOOD
void goodExample() {
    std::unique_ptr<int> ptr = std::make_unique<int>(42);
    // ... code ...
    // Automatic cleanup
}
```

2. **Use smart pointers appropriately**
```cpp
// Use unique_ptr for single ownership
std::unique_ptr<Resource> resource = std::make_unique<Resource>();

// Use shared_ptr only when you need shared ownership
std::shared_ptr<Resource> shared = std::make_shared<Resource>();

// Use weak_ptr to break circular references
std::weak_ptr<Resource> weak = shared;
```

3. **Prefer containers over raw arrays**
```cpp
// BAD
int* array = new int[100];
// ... code ...
delete[] array;

// GOOD
std::vector<int> array(100);
// Automatic cleanup
```

4. **Use move semantics for efficiency**
```cpp
// GOOD: Move large objects
std::vector<LargeObject> processData(std::vector<LargeObject> data) {
    // Process data...
    return std::move(data);  // Move instead of copy
}
```

### Common Pitfalls

1. **Dangling pointers**
```cpp
// BAD: Dangling pointer
int* getPointer() {
    int value = 42;
    return &value;  // Returns pointer to local variable
}

// GOOD: Return by value or use smart pointers
std::unique_ptr<int> getPointer() {
    return std::make_unique<int>(42);
}
```

2. **Memory leaks**
```cpp
// BAD: Memory leak
void leakyFunction() {
    int* ptr = new int(42);
    // Forgot to delete ptr
}

// GOOD: Use RAII
void safeFunction() {
    std::unique_ptr<int> ptr = std::make_unique<int>(42);
    // Automatic cleanup
}
```

3. **Double deletion**
```cpp
// BAD: Double deletion
int* ptr = new int(42);
delete ptr;
delete ptr;  // Undefined behavior!

// GOOD: Use smart pointers
std::unique_ptr<int> ptr = std::make_unique<int>(42);
// Automatic cleanup, no double deletion possible
```

4. **Circular references with shared_ptr**
```cpp
// BAD: Circular reference
class Node {
    std::shared_ptr<Node> parent;
    std::shared_ptr<Node> child;
};

// GOOD: Use weak_ptr to break cycles
class SafeNode {
    std::weak_ptr<SafeNode> parent;
    std::shared_ptr<SafeNode> child;
};
```

## Performance Considerations

### Memory Layout and Cache Efficiency

```cpp
#include <chrono>
#include <iostream>

// Bad: Poor cache locality
struct BadLayout {
    int id;
    char padding[60];  // Wastes cache space
    double value;
    char morePadding[60];
};

// Good: Better cache locality
struct GoodLayout {
    int id;
    double value;
    // Group related data together
};

void cacheEfficiencyExample() {
    const size_t count = 1000000;
    
    // Bad layout
    std::vector<BadLayout> badData(count);
    
    // Good layout
    std::vector<GoodLayout> goodData(count);
    
    // Initialize data
    for (size_t i = 0; i < count; ++i) {
        badData[i].id = i;
        badData[i].value = i * 3.14;
        goodData[i].id = i;
        goodData[i].value = i * 3.14;
    }
    
    // Measure access time
    auto start = std::chrono::high_resolution_clock::now();
    
    double sum = 0;
    for (const auto& item : goodData) {
        sum += item.value;
    }
    
    auto end = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end - start);
    
    std::cout << "Sum: " << sum << std::endl;
    std::cout << "Time: " << duration.count() << " microseconds" << std::endl;
}
```

### Memory Allocation Strategies

```cpp
#include <memory_resource>

class LinearAllocator : public std::pmr::memory_resource {
private:
    char* memory;
    size_t size;
    size_t offset;
    
public:
    LinearAllocator(size_t s) : size(s), offset(0) {
        memory = static_cast<char*>(std::aligned_alloc(alignof(std::max_align_t), s));
    }
    
    ~LinearAllocator() {
        std::free(memory);
    }
    
protected:
    void* do_allocate(size_t bytes, size_t alignment) override {
        size_t alignedOffset = (offset + alignment - 1) & ~(alignment - 1);
        if (alignedOffset + bytes > size) {
            throw std::bad_alloc();
        }
        
        void* result = memory + alignedOffset;
        offset = alignedOffset + bytes;
        return result;
    }
    
    void do_deallocate(void*, size_t, size_t) override {
        // Linear allocator doesn't support deallocation
    }
    
    bool do_is_equal(const memory_resource& other) const noexcept override {
        return this == &other;
    }
};

void allocatorExample() {
    LinearAllocator allocator(1024 * 1024);  // 1MB
    
    // Use with containers
    std::pmr::vector<int> vec(&allocator);
    vec.reserve(1000);
    
    for (int i = 0; i < 1000; ++i) {
        vec.push_back(i);
    }
    
    std::cout << "Vector size: " << vec.size() << std::endl;
}
```

## Exercises

### Exercise 1: Smart Pointer Implementation
Implement a simple `unique_ptr` class that provides basic functionality:
- Constructor, destructor
- Move constructor and move assignment
- `get()`, `reset()`, `release()` methods
- `operator*` and `operator->`

### Exercise 2: Memory Pool
Create a memory pool allocator that:
- Pre-allocates a large block of memory
- Provides `allocate()` and `deallocate()` methods
- Tracks used and free blocks
- Handles alignment requirements

### Exercise 3: RAII File Wrapper
Implement a file wrapper class that:
- Opens a file in the constructor
- Closes the file in the destructor
- Provides read/write methods
- Handles exceptions properly

### Exercise 4: Circular Buffer
Create a circular buffer class that:
- Uses a fixed-size array
- Provides `push()` and `pop()` operations
- Handles overflow/underflow conditions
- Uses move semantics for efficiency

## Further Reading

### Books
- "Effective Modern C++" by Scott Meyers
- "C++ Primer" by Stanley Lippman, Josée Lajoie, and Barbara Moo
- "The C++ Programming Language" by Bjarne Stroustrup
- "Memory Management in C++" by Andrei Alexandrescu

### Online Resources
- [cppreference.com](https://en.cppreference.com/) - Comprehensive C++ reference
- [C++ Core Guidelines](https://isocpp.github.io/CppCoreGuidelines/) - Best practices
- [Modern C++ Features](https://github.com/AnthonyCalandra/modern-cpp-features) - Feature overview

### Key Concepts to Explore Further
- Exception safety guarantees
- Custom deleters and allocators
- Memory-mapped I/O
- Lock-free programming
- Garbage collection alternatives
- Memory profiling and debugging tools

---

## Conclusion

Modern C++ provides powerful tools for memory management that make your code safer, more efficient, and easier to maintain. By following RAII principles, using smart pointers appropriately, and understanding move semantics, you can write robust C++ code that avoids common memory-related bugs.

Remember:
- **RAII is your friend** - Let objects manage their own resources
- **Smart pointers over raw pointers** - Use `unique_ptr`, `shared_ptr`, and `weak_ptr`
- **Move when you can, copy when you must** - Prefer move semantics for efficiency
- **Containers over arrays** - Use standard containers for automatic memory management
- **Profile before optimizing** - Measure performance before making changes

Happy coding, and may your memory management be both safe and efficient!