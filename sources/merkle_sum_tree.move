/// Module: merkle_sum_tree
module merkle_sum_tree::merkle_sum_tree;

use sui::{hash, bcs};

// Variable-arity Merkle Sum Tree

public struct Node has drop {
    value: u64,
    hash: vector<u8>, // general data hash
}

public struct MultiNode has drop {
    sum: u64,
    accumulatedHash: vector<u8>,
    hashes: vector<vector<u8>>,
}

public struct Root {
    sum: u64,
    hash: vector<u8>,
}

public fun new_node(value: u64, dataHash: vector<u8>): Node {
    Node {
        value: value,
        hash: dataHash
    }
}

public fun new_multinode(mut nodes: vector<Node>): MultiNode {
    let mut ret = MultiNode {
        sum: 0,
        accumulatedHash: vector::empty(),
        hashes: vector::empty(),
    };

    let mut accumulatedHash = vector::empty();

    while (!vector::is_empty(&nodes)) {
        let node = vector::pop_back(&mut nodes);
        ret.sum = ret.sum + node.value; // FIXME make checked

        let mut message = vector::empty<u8>();
        vector::append(&mut message, bcs::to_bytes(&node.value));
        vector::append(&mut message, node.hash);
        let nodeHash = hash::blake2b256(&message);

        let mut accumulatedMessage = vector::empty<u8>();
        vector::append(&mut accumulatedMessage, copy_u8_vector(&accumulatedHash));
        vector::append(&mut accumulatedMessage, copy_u8_vector(&nodeHash));
        accumulatedHash = hash::blake2b256(&accumulatedMessage); 

        vector::push_back(&mut ret.hashes, nodeHash);
    };
    ret.accumulatedHash = accumulatedHash;
    vector::destroy_empty(nodes);
    ret 
}

public fun multi_node_as_node(multi_node: MultiNode): Node {
    let MultiNode { sum: sum, accumulatedHash: accumulatedHash, hashes: _ } = multi_node;
    Node {
        value: sum,
        hash: accumulatedHash,
    }
}

public fun node_as_root(node: Node): Root {
    let Node { value: value, hash: hash } = node;
    Root {
        sum: value,
        hash: hash,
    }
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
