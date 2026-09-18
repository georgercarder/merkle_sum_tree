/// Module: merkle_sum_tree
module merkle_sum_tree::merkle_sum_tree;

// Variable-arity Merkle Sum Tree

public struct Leaf {
    value u64,
    dataHash vector<u8>, // general data hash
}

public struct Node {
    sum u64,
    hashes vector<vector<u8>>,
}

// TODO
public fun hash_to_node(): Node {

}
