/// Module: merkle_sum_tree
module merkle_sum_tree::merkle_sum_tree;

use sui::{hash, bcs};

// Variable-arity Merkle Sum Tree

public struct Leaf has drop {
    value: u64,
    dataHash: vector<u8>, // general data hash
}

public struct Node has drop {
    sum: u64,
    accumulatedHash: vector<u8>,
    hashes: vector<vector<u8>>,
}

public struct Root {
    sum: u64,
    hash: vector<u8>,
}

public fun node_as_root(node: Node): Root {
    let Node { sum: sum, accumulatedHash: accumulatedHash, hashes: _ } = node;
    Root {
        sum: sum,
        hash: accumulatedHash,
    }
}

public fun hash_to_node(mut leaves: vector<Leaf>): Node {
    let mut node = Node {
        sum: 0,
        accumulatedHash: vector::empty(),
        hashes: vector::empty(),
    };

    let mut accumulatedHash = vector::empty();

    while (!vector::is_empty(&leaves)) {
        let leaf = vector::pop_back(&mut leaves);
        node.sum = node.sum + leaf.value; // FIXME make checked

        let mut message = vector::empty<u8>();
        vector::append(&mut message, bcs::to_bytes(&leaf.value));
        vector::append(&mut message, leaf.dataHash);
        let leafHash = hash::blake2b256(&message);

        let mut accumulatedMessage = vector::empty<u8>();
        vector::append(&mut accumulatedMessage, copy_u8_vector(&accumulatedHash));
        vector::append(&mut accumulatedMessage, copy_u8_vector(&leafHash));
        accumulatedHash = hash::blake2b256(&accumulatedMessage); 

        vector::push_back(&mut node.hashes, leafHash);
    };
    node.accumulatedHash = accumulatedHash;
    vector::destroy_empty(leaves);
    node
}

public fun copy_u8_vector(v: &vector<u8>): vector<u8> {
    let mut ret = vector::empty<u8>();
    let length = vector::length(v);
    let mut i = 0;
    while (i < length) {
        let val = *vector::borrow(v, i); 
        vector::push_back(&mut ret, val);
        i = i + 1;
    };
    ret
}
