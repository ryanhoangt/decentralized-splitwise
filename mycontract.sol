// Please paste your contract's solidity code here
// Note that writing a contract here WILL NOT deploy it and allow you to access it from your client
// You should write and develop your contract in Remix and then, before submitting, copy and paste it here
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Splitwise {

    struct Debt {
        uint32 amount;
    }

    mapping (address => mapping(address => Debt)) internal debts_map;

    // === PUBLIC FUNCTIONS ===
    function lookup(address debtor, address creditor) public view returns (uint32 ret) {
        ret = debts_map[debtor][creditor].amount;
    }

    function add_IOU(address creditor, uint32 amount, address[] memory cre_to_debt_path, uint32 min_on_cycle) public {
        address debtor = msg.sender;
        require(debtor != creditor, "Cannot owe yourself.");

        // reference to current iou
        Debt storage iou = debts_map[debtor][creditor];
        
        if (min_on_cycle == 0) {
            iou.amount += amount;
            return;
        }

        require(min_on_cycle <= (iou.amount + amount), "The min value on cycle cannot be larger than your iou amount.");
        require(verify_and_fix_path(creditor, debtor, cre_to_debt_path, min_on_cycle));
        iou.amount += (amount - min_on_cycle);
    }

    // === PRIVATE HELPERS ===
    // Verify the path is valid and fix it. The path can be partially fixed
    // so caller is responsible for undoing a partially fixed path (by using 'require')
    // Return true if the path is completely fixed, false otherwise.
    function verify_and_fix_path(address start, address end, address[] memory path, uint32 min_on_cycle) private returns (bool) {
        if (start != path[0] || end != path[path.length - 1]) return false;

        // Allow cycles with maximum of 10 addresses in between 
        if (path.length > 12) return false;

        for (uint i = 1; i < path.length; i++) {
            Debt storage iou = debts_map[path[i-1]][path[i]];
            if (iou.amount == 0 || iou.amount < min_on_cycle) return false;
            else iou.amount -= min_on_cycle;
        }

        return true;
    }
    
}

