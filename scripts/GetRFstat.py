#!/usr/bin/python
import json
import sys


def recurse_branch(tree):
    """Returns deepest_node, total_leaves, sum_depths"""
    if 'left' in tree:
        deepest_l, leaves_l, sum_depths_l = recurse_branch(tree['left'])
        deepest_r, leaves_r, sum_depths_r = recurse_branch(tree['right'])
        sum_leaves = leaves_l + leaves_r
        return 1 + max(deepest_l, deepest_r), sum_leaves, sum_leaves + sum_depths_l + sum_depths_r
    else:
        return 0, 1, 0


def analyse_trees(trees):
    """Prints summary data on trees."""
    num_trees = float(len(trees))  # float to ensure non-integer division
    sum_deepest = 0
    sum_leaves = 0
    sum_depths = 0
    for tree in trees:
        deepest_t, sum_leaves_t, sum_depths_t = recurse_branch(tree['rootNode'])
        sum_deepest += deepest_t
        sum_leaves += sum_leaves_t
        sum_depths += sum_depths_t
    average_tree_depth = sum_deepest / num_trees
    average_branch_depth = float(sum_depths) / sum_leaves
    average_leaves = sum_leaves / num_trees
    print('\n'.join([
        "Average tree depth: " + str(average_tree_depth),
        "Average branch depth: " + str(average_branch_depth),
        "Average leaves per tree: " + str(average_leaves),
        "Average nodes per tree: " + str(average_leaves - 1),
    ]))


if __name__ == '__main__':
    with open(sys.argv[1], 'r') as json_file:
        full_data = json.load(json_file)
    analyse_trees(full_data['trees'])

