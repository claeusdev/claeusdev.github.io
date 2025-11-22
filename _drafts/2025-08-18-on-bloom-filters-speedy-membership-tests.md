---
layout: post
title: "On Bloom Filters: Speedy Membership Tests"
date: 2025-08-18
categories: algorithms data-structures
---

When building distributed systems or working with large datasets, we often need to check if an element exists in a set. A standard hash set works perfectly for this—until you have billions of items and limited memory. This is where **Bloom filters** shine.

A Bloom filter is a probabilistic data structure that tells you whether an element **possibly exists** in a set or **definitely does not**. It trades a small amount of accuracy (false positives) for massive savings in space and speed.

## How It Works

At its core, a Bloom filter is just a bit array of size $m$, initially all set to 0.

To add an item:
1. Hash the item using $k$ different hash functions.
2. Each hash function produces an index between 0 and $m-1$.
3. Set the bits at these $k$ indices to 1.

To check if an item exists:
1. Hash the item using the same $k$ hash functions.
2. Check the bits at all $k$ indices.
3. If **any** bit is 0, the item is **definitely not** in the set.
4. If **all** bits are 1, the item **probably** is in the set.

Why "probably"? Because those bits could have been set by a combination of other items. This is a **false positive**.

## Implementation in OCaml

Let's build a simple Bloom filter in OCaml. We'll use the `Digest` module for hashing, though in production you'd want non-cryptographic hashes like MurmurHash or FNV for speed.

```ocaml
module BloomFilter = struct
  type t = {
    bits : bytes;
    size : int;
    hash_count : int;
  }

  (* Create a new Bloom filter *)
  let create ~size ~hash_count =
    {
      bits = Bytes.make size '\000';
      size = size * 8; (* size in bits *)
      hash_count;
    }

  (* Simple hash function generator *)
  let hash_indices item size count =
    let base_hash = Digest.string item |> Digest.to_hex in
    let rec loop i acc =
      if i = count then acc
      else
        (* In a real implementation, use a better seeding strategy *)
        let h = Hashtbl.hash (base_hash ^ string_of_int i) in
        let idx = abs h mod size in
        loop (i + 1) (idx :: acc)
    in
    loop 0 []

  (* Add an item to the filter *)
  let add t item =
    let indices = hash_indices item t.size t.hash_count in
    List.iter (fun idx ->
      let byte_pos = idx / 8 in
      let bit_pos = idx mod 8 in
      let byte = Bytes.get_uint8 t.bits byte_pos in
      let new_byte = byte lor (1 lsl bit_pos) in
      Bytes.set_uint8 t.bits byte_pos new_byte
    ) indices

  (* Check if an item exists *)
  let mem t item =
    let indices = hash_indices item t.size t.hash_count in
    List.for_all (fun idx ->
      let byte_pos = idx / 8 in
      let bit_pos = idx mod 8 in
      let byte = Bytes.get_uint8 t.bits byte_pos in
      (byte land (1 lsl bit_pos)) <> 0
    ) indices
end
```

## Usage Example

```ocaml
let () =
  let bf = BloomFilter.create ~size:1024 ~hash_count:3 in
  
  BloomFilter.add bf "apple";
  BloomFilter.add bf "banana";
  
  Printf.printf "Contains 'apple'? %b\n" (BloomFilter.mem bf "apple");
  Printf.printf "Contains 'grape'? %b\n" (BloomFilter.mem bf "grape");
  
  (* Output:
     Contains 'apple'? true
     Contains 'grape'? false
  *)
```

## Real-World Applications

1.  **Databases (Cassandra, PostgreSQL)**: Before reading a disk block to find a row, the DB checks a Bloom filter. If it returns "no", the disk read is skipped, saving massive I/O.
2.  **Web Browsers**: Chrome used to use Bloom filters to check if a URL was malicious. If the filter said "maybe", it would perform a more expensive check against a remote server.
3.  **CDNs**: To avoid caching "one-hit wonders" (content requested only once), CDNs use Bloom filters to track request frequency efficiently.

## Tuning the Filter

The probability of a false positive depends on the size of the bit array ($m$), the number of hash functions ($k$), and the number of elements inserted ($n$).

The optimal number of hash functions is given by:

$$ k = \frac{m}{n} \ln 2 $$

This means for a given expected number of items and desired false positive rate, you can calculate exactly how much memory you need.

## Conclusion

Bloom filters are a fantastic example of a trade-off in computer science: by accepting a tiny margin of error, we gain incredible performance and space efficiency. They are ubiquitous in distributed systems and are a tool every engineer should have in their belt.
