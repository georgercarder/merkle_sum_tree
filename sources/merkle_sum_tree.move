/// Module: merkle_sum_tree
module merkle_sum_tree::merkle_sum_tree;

use sui::{crypto, bcs};

// Variable-arity Merkle Sum Tree

public struct Leaf {
    value u64,
    dataHash vector<u8>, // general data hash
}

public struct Node {
    sum u64,
    accumulatedHash vector<u8>,
    hashes vector<vector<u8>>,
}

public fun hash_to_node(mut leaves: vector<Leaf>): Node {
    let mut node = Node {
        sum: 0,
        accumulatedHash: vector::empty(),
        hashes: vector::empty(),
    };

    while (!vector::is_empty(&leaves)) {
        let leaf = vector::pop_back(&mut leaves);
        node.sum = node.sum + leaf.value; // FIXME make checked

        let mut messsage = vector::empty<u8>();
        vector::append(&mut message, bcs::to_bytes(&leaf.value));
        vector::append(&mut message, leaf.dataHash);
        let leafHash = crypto::blake2b256(&message);
        vector::push_back(&mut node.hashes, leafHash);

        let mut accumulatedMessage = vector::empty<u8>();
        vector::append(&mut accumulatedHash, &node.accumulatedHash);
        vector::append(&mut accumulatedHash, &leafHash);
        node.accumulatedHash = crypto::blake2b256(&accumulatedMessage); 
    };
    vector::destroy_empty(leaves);
    node
}
