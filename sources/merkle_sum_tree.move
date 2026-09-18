/// Module: merkle_sum_tree
module merkle_sum_tree::merkle_sum_tree;

use sui::{hash, bcs};

// Variable-arity Merkle Sum Tree

#[error(code = 1)]
const EOverflow: vector<u8> = b"u128 addition overflow";

public struct Node has drop, copy {
    value: u128,
    dataHash: vector<u8>, // general data hash
}

public struct MultiNode has drop {
    sum: u128,
    accumulatedHash: vector<u8>,
    hashes: vector<vector<u8>>,
}

public struct Root has drop {
    sum: u128,
    hash: vector<u8>,
}

// whether level nodes are ordered are up to the implementing client
// but in practice, a client SHOULD consistently order each level with respect to 
// the `dataHash` parameter otherwise reconstructing a Merkle Sum Tree matching their 
// initial construction would not be well-defined. Ordering on the smart contract 
// level is not enforced for the sake of efficiency, as a proof not following the order 
// of a client's construction would simply not validate. The client team should be sure 
// to enforce consistent ordering at each level.

public struct Level has drop {
    left_siblings: vector<Node>,
    right_siblings: vector<Node>,
}

public fun verify_proof(
    node: Node, 
    mut levels: vector<Level>,
    root: Root,
): bool {
    let Node { value, dataHash } = node;
    let mut focus = Node { value, dataHash };
    while (!vector::is_empty(&levels)) {
        let l = vector::pop_back(&mut levels);

        let mut nodes = vector::empty<Node>();
        append_nodes(&mut nodes, &l.left_siblings);
        append_node(&mut nodes, &focus);
        append_nodes(&mut nodes, &l.right_siblings);

        let multi_node = new_multinode(nodes);
        focus = multi_node_as_node(multi_node);
    };
    let result = node_as_root(focus);
    
    vector::destroy_empty(levels);
    roots_are_same(result, root)
}

public fun new_node(value: u128, dataHash: vector<u8>): Node {
    Node {
        value: value,
        dataHash: dataHash
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
        let mut checked = std::u128::checked_add(ret.sum, node.value);
        assert!(option::is_some(&checked), EOverflow);
        ret.sum = option::extract(&mut checked);

        let mut message = vector::empty<u8>();
        vector::append(&mut message, bcs::to_bytes(&node.value));
        vector::append(&mut message, node.dataHash);
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
        dataHash: accumulatedHash,
    }
}

public fun node_as_root(node: Node): Root {
    let Node { value: value, dataHash: dataHash } = node;
    Root {
        sum: value,
        hash: dataHash,
    }
}

public fun roots_are_same(a: Root, b: Root): bool {
    (a.sum == b.sum) && (a.hash == b.hash)
}

public fun append_nodes(to: &mut vector<Node>, from: &vector<Node>) {
    let length = vector::length(from);
    let mut i = 0;
    while (i < length) {
        let n = vector::borrow(from, i);
        vector::push_back(to, *n);
        i = i + 1;
    };
}

public fun append_node(nodes: &mut vector<Node>, node: &Node) {
    vector::push_back(nodes, *node);
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
