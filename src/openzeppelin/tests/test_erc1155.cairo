use openzeppelin::introspection::erc165;
use openzeppelin::token::erc1155;
use openzeppelin::token::erc1155::ERC1155;

use array::ArrayTrait;
use starknet::contract_address_const;
use starknet::ContractAddress;
use starknet::ContractAddressZeroable;
use starknet::testing::set_caller_address;
use integer::u256;
use integer::u256_from_felt252;
use traits::Into;
use zeroable::Zeroable;

const URI: felt252 = 333;

fn ZERO() -> ContractAddress {
    Zeroable::zero()
}
fn OWNER() -> ContractAddress {
    contract_address_const::<1>()
}
fn RECIPIENT() -> ContractAddress {
    contract_address_const::<2>()
}
fn SPENDER() -> ContractAddress {
    contract_address_const::<3>()
}
fn OPERATOR() -> ContractAddress {
    contract_address_const::<4>()
}
fn OTHER() -> ContractAddress {
    contract_address_const::<5>()
}

///
/// Setup
///

fn setup() {
    ERC1155::initializer(URI);
}

///
/// Initialize
///

#[test]
#[available_gas(2000000)]
fn test_initialize() {
    setup();

    assert(ERC1155::uri(17.into()) == URI, 'Unexpected URI');
    assert(ERC1155::uri(42.into()) == URI, 'Unexpected URI');
    assert(ERC1155::balance_of(OWNER(), 17.into()) == 0.into(), 'Balance should be zero');
    assert(ERC1155::balance_of(OWNER(), 42.into()) == 0.into(), 'Balance should be zero');

    assert(ERC1155::supports_interface(erc1155::IERC1155_ID), 'Missing interface ID');
    assert(ERC1155::supports_interface(erc1155::IERC1155_METADATA_ID), 'missing interface ID');
    assert(ERC1155::supports_interface(erc165::IERC165_ID), 'missing interface ID');
    assert(!ERC1155::supports_interface(erc165::INVALID_ID), 'invalid interface ID');
}

///
/// Getters
///

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC1155: invalid account', ))]
fn test_balance_of_zero() {
    ERC1155::balance_of(ZERO(), 17.into());
}

#[test]
#[available_gas(2000000)]
fn test_balance_of_non_zero() {
    let zero:     u256 = 0.into();
    let id:       u256 = 17.into();
    let other_id: u256 = 42.into();
    let amount:   u256 = 69.into();

    assert(ERC1155::balance_of(OWNER(), id)       == zero, 'Invalid balance');
    assert(ERC1155::balance_of(OWNER(), other_id) == zero, 'Invalid balance');
    assert(ERC1155::balance_of(OTHER(), id)       == zero, 'Invalid balance');
    assert(ERC1155::balance_of(OTHER(), other_id) == zero, 'Invalid balance');

    ERC1155::_mint(OWNER(), id, amount, ArrayTrait::new());

    assert(ERC1155::balance_of(OWNER(), id)       == amount, 'Invalid balance');
    assert(ERC1155::balance_of(OWNER(), other_id) == zero,   'Invalid balance');
    assert(ERC1155::balance_of(OTHER(), id)       == zero,   'Invalid balance');
    assert(ERC1155::balance_of(OTHER(), other_id) == zero,   'Invalid balance');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC1155: invalid account', ))]
fn test_balance_of_batch_zero() {
    let mut accounts: Array<ContractAddress> = ArrayTrait::new();
    let mut ids: Array<u256> = ArrayTrait::new();
    accounts.append(OWNER()); ids.append(17.into());
    accounts.append(ZERO());  ids.append(17.into());

    ERC1155::balance_of_batch(accounts, ids);
}

#[test]
#[available_gas(2000000)]
fn test_balance_of_batch_non_zero() {
    let zero:     u256 = 0.into();
    let id:       u256 = 17.into();
    let other_id: u256 = 42.into();
    let amount:   u256 = 69.into();

    let mut accounts: Array<ContractAddress> = ArrayTrait::new();
    accounts.append(OWNER());
    accounts.append(OWNER());
    accounts.append(OTHER());
    accounts.append(OTHER());

    // let mut accounts: Array<ContractAddress> = ArrayTrait::new();
    let mut ids: Array<u256> = ArrayTrait::new();
    // accounts.append(OWNER()); ids.append(id);
    // accounts.append(OWNER()); ids.append(other_id);
    // accounts.append(OTHER()); ids.append(id);
    // accounts.append(OTHER()); ids.append(other_id);

    let mut resultBefore = ERC1155::balance_of_batch(accounts, ids);
    assert(resultBefore.len() == 4_u32, 'Invalid return length');
    assert(*resultBefore.at(0_u32) == zero, 'Invalid balance');
    assert(*resultBefore.at(1_u32) == zero, 'Invalid balance');
    assert(*resultBefore.at(2_u32) == zero, 'Invalid balance');
    assert(*resultBefore.at(3_u32) == zero, 'Invalid balance');

    ERC1155::_mint(OWNER(), id, amount, ArrayTrait::new());

    let mut resultAfter = ERC1155::balance_of_batch(accounts, ids);
    assert(resultAfter.len() == 4_u32, 'Invalid return length');
    assert(*resultAfter.at(0_u32) == amount, 'Invalid balance');
    assert(*resultAfter.at(1_u32) == zero,   'Invalid balance');
    assert(*resultAfter.at(2_u32) == zero,   'Invalid balance');
    assert(*resultAfter.at(3_u32) == zero,   'Invalid balance');
}




// ///
// /// approve & _approve
// ///

// #[test]
// #[available_gas(2000000)]
// fn test_approve_from_owner() {
//     setup();

//     set_caller_address(OWNER());
//     ERC1155::approve(SPENDER(), TOKEN_ID());
//     assert(ERC1155::get_approved(TOKEN_ID()) == SPENDER(), 'Spender not approved correctly');
// }

// #[test]
// #[available_gas(2000000)]
// fn test_approve_from_operator() {
//     setup();

//     set_caller_address(OWNER());
//     ERC1155::set_approval_for_all(OPERATOR(), true);

//     set_caller_address(OPERATOR());
//     ERC1155::approve(SPENDER(), TOKEN_ID());
//     assert(ERC1155::get_approved(TOKEN_ID()) == SPENDER(), 'Spender not approved correctly');
// }

// #[test]
// #[available_gas(2000000)]
// #[should_panic(expected: ('ERC1155: unauthorized caller', ))]
// fn test_approve_from_unauthorized() {
//     setup();

//     set_caller_address(OTHER());
//     ERC1155::approve(SPENDER(), TOKEN_ID());
// }

// #[test]
// #[available_gas(2000000)]
// #[should_panic(expected: ('ERC1155: approval to owner', ))]
// fn test_approve_to_owner() {
//     setup();

//     set_caller_address(OWNER());
//     ERC1155::approve(OWNER(), TOKEN_ID());
// }

// #[test]
// #[available_gas(2000000)]
// #[should_panic(expected: ('ERC1155: invalid token ID', ))]
// fn test_approve_nonexistent() {
//     ERC1155::approve(SPENDER(), TOKEN_ID());
// }

// #[test]
// #[available_gas(2000000)]
// fn test__approve() {
//     setup();

//     ERC1155::_approve(SPENDER(), TOKEN_ID());
//     assert(ERC1155::get_approved(TOKEN_ID()) == SPENDER(), 'Spender not approved correctly');
// }

// #[test]
// #[available_gas(2000000)]
// #[should_panic(expected: ('ERC1155: approval to owner', ))]
// fn test__approve_to_owner() {
//     setup();

//     ERC1155::_approve(OWNER(), TOKEN_ID());
// }

// #[test]
// #[available_gas(2000000)]
// #[should_panic(expected: ('ERC1155: invalid token ID', ))]
// fn test__approve_nonexistent() {
//     ERC1155::_approve(SPENDER(), TOKEN_ID());
// }

// ///
// /// set_approval_for_all & _set_approval_for_all
// ///

// #[test]
// #[available_gas(2000000)]
// fn test_set_approval_for_all() {
//     set_caller_address(OWNER());
//     assert(!ERC1155::is_approved_for_all(OWNER(), OPERATOR()), 'Invalid default value');

//     ERC1155::set_approval_for_all(OPERATOR(), true);
//     assert(ERC1155::is_approved_for_all(OWNER(), OPERATOR()), 'Operator not approved correctly');

//     ERC1155::set_approval_for_all(OPERATOR(), false);
//     assert(!ERC1155::is_approved_for_all(OWNER(), OPERATOR()), 'Operator not approved correctly');
// }

// #[test]
// #[available_gas(2000000)]
// #[should_panic(expected: ('ERC1155: self approval', ))]
// fn test_set_approval_for_all_owner_equal_operator_true() {
//     set_caller_address(OWNER());
//     ERC1155::set_approval_for_all(OWNER(), true);
// }

// #[test]
// #[available_gas(2000000)]
// #[should_panic(expected: ('ERC1155: self approval', ))]
// fn test_set_approval_for_all_owner_equal_operator_false() {
//     set_caller_address(OWNER());
//     ERC1155::set_approval_for_all(OWNER(), false);
// }

// #[test]
// #[available_gas(2000000)]
// fn test__set_approval_for() {
//     assert(!ERC1155::is_approved_for_all(OWNER(), OPERATOR()), 'Invalid default value');

//     ERC1155::_set_approval_for_all(OWNER(), OPERATOR(), true);
//     assert(ERC1155::is_approved_for_all(OWNER(), OPERATOR()), 'Operator not approved correctly');

//     ERC1155::_set_approval_for_all(OWNER(), OPERATOR(), false);
//     assert(!ERC1155::is_approved_for_all(OWNER(), OPERATOR()), 'Operator not approved correctly');
// }

// #[test]
// #[available_gas(2000000)]
// #[should_panic(expected: ('ERC1155: self approval', ))]
// fn test__set_approval_for_all_owner_equal_operator_true() {
//     ERC1155::_set_approval_for_all(OWNER(), OWNER(), true);
// }

// #[test]
// #[available_gas(2000000)]
// #[should_panic(expected: ('ERC1155: self approval', ))]
// fn test__set_approval_for_all_owner_equal_operator_false() {
//     ERC1155::_set_approval_for_all(OWNER(), OWNER(), false);
// }

// ///
// /// transfer_from
// ///

// #[test]
// #[available_gas(2000000)]
// fn test_transfer_from_owner() {
//     setup();

//     // set approval to check reset
//     ERC1155::_approve(OTHER(), TOKEN_ID());

//     assert(ERC1155::owner_of(TOKEN_ID()) == OWNER(), 'Ownership before');
//     assert(ERC1155::balance_of(OWNER()) == 1.into(), 'Balance of owner before');
//     assert(ERC1155::balance_of(RECIPIENT()) == 0.into(), 'Balance of recipient before');
//     assert(ERC1155::get_approved(TOKEN_ID()) == OTHER(), 'Approval not implicitly reset');

//     set_caller_address(OWNER());
//     ERC1155::transfer_from(OWNER(), RECIPIENT(), TOKEN_ID());

//     assert(ERC1155::owner_of(TOKEN_ID()) == RECIPIENT(), 'Ownership after');
//     assert(ERC1155::balance_of(OWNER()) == 0.into(), 'Balance of owner after');
//     assert(ERC1155::balance_of(RECIPIENT()) == 1.into(), 'Balance of recipient after');
//     assert(ERC1155::get_approved(TOKEN_ID()).is_zero(), 'Approval not implicitly reset');
// }

// #[test]
// #[available_gas(2000000)]
// #[should_panic(expected: ('ERC1155: invalid token ID', ))]
// fn test_transfer_from_nonexistent() {
//     ERC1155::transfer_from(ZERO(), RECIPIENT(), TOKEN_ID());
// }

// #[test]
// #[available_gas(2000000)]
// #[should_panic(expected: ('ERC1155: invalid receiver', ))]
// fn test_transfer_from_to_zero() {
//     setup();

//     set_caller_address(OWNER());
//     ERC1155::transfer_from(OWNER(), ZERO(), TOKEN_ID());
// }

// #[test]
// #[available_gas(2000000)]
// fn test_transfer_from_to_owner() {
//     setup();

//     assert(ERC1155::owner_of(TOKEN_ID()) == OWNER(), 'Ownership before');
//     assert(ERC1155::balance_of(OWNER()) == 1.into(), 'Balance of owner before');

//     set_caller_address(OWNER());
//     ERC1155::transfer_from(OWNER(), OWNER(), TOKEN_ID());

//     assert(ERC1155::owner_of(TOKEN_ID()) == OWNER(), 'Ownership after');
//     assert(ERC1155::balance_of(OWNER()) == 1.into(), 'Balance of owner after');
// }

// #[test]
// #[available_gas(2000000)]
// fn test_transfer_from_approved() {
//     setup();

//     assert(ERC1155::owner_of(TOKEN_ID()) == OWNER(), 'Ownership before');
//     assert(ERC1155::balance_of(OWNER()) == 1.into(), 'Balance of owner before');
//     assert(ERC1155::balance_of(RECIPIENT()) == 0.into(), 'Balance of recipient before');

//     set_caller_address(OWNER());
//     ERC1155::approve(OPERATOR(), TOKEN_ID());

//     set_caller_address(OPERATOR());
//     ERC1155::transfer_from(OWNER(), RECIPIENT(), TOKEN_ID());

//     assert(ERC1155::owner_of(TOKEN_ID()) == RECIPIENT(), 'Ownership after');
//     assert(ERC1155::balance_of(OWNER()) == 0.into(), 'Balance of owner after');
//     assert(ERC1155::balance_of(RECIPIENT()) == 1.into(), 'Balance of recipient after');
//     assert(ERC1155::get_approved(TOKEN_ID()) == ZERO(), 'Approval not implicitly reset');
// }

// #[test]
// #[available_gas(2000000)]
// fn test_transfer_from_approved_for_all() {
//     setup();

//     assert(ERC1155::owner_of(TOKEN_ID()) == OWNER(), 'Ownership before');
//     assert(ERC1155::balance_of(OWNER()) == 1.into(), 'Balance of owner before');
//     assert(ERC1155::balance_of(RECIPIENT()) == 0.into(), 'Balance of recipient before');

//     set_caller_address(OWNER());
//     ERC1155::set_approval_for_all(OPERATOR(), true);

//     set_caller_address(OPERATOR());
//     ERC1155::transfer_from(OWNER(), RECIPIENT(), TOKEN_ID());

//     assert(ERC1155::owner_of(TOKEN_ID()) == RECIPIENT(), 'Ownership after');
//     assert(ERC1155::balance_of(OWNER()) == 0.into(), 'Balance of owner after');
//     assert(ERC1155::balance_of(RECIPIENT()) == 1.into(), 'Balance of recipient after');
//     assert(ERC1155::get_approved(TOKEN_ID()) == ZERO(), 'Approval not implicitly reset');
// }

// #[test]
// #[available_gas(2000000)]
// #[should_panic(expected: ('ERC1155: unauthorized caller', ))]
// fn test_transfer_from_unauthorized() {
//     setup();

//     set_caller_address(OTHER());
//     ERC1155::transfer_from(OWNER(), RECIPIENT(), TOKEN_ID());
// }

// #[test]
// #[available_gas(2000000)]
// fn test__transfer() {
//     setup();

//     assert(ERC1155::owner_of(TOKEN_ID()) == OWNER(), 'Ownership before');
//     assert(ERC1155::balance_of(OWNER()) == 1.into(), 'Balance of owner before');
//     assert(ERC1155::balance_of(RECIPIENT()) == 0.into(), 'Balance of recipient before');

//     ERC1155::_transfer(OWNER(), RECIPIENT(), TOKEN_ID());

//     assert(ERC1155::owner_of(TOKEN_ID()) == RECIPIENT(), 'Ownership after');
//     assert(ERC1155::balance_of(OWNER()) == 0.into(), 'Balance of owner after');
//     assert(ERC1155::balance_of(RECIPIENT()) == 1.into(), 'Balance of recipient after');
//     assert(ERC1155::get_approved(TOKEN_ID()) == ZERO(), 'Approval not implicitly reset');
// }

// #[test]
// #[available_gas(2000000)]
// #[should_panic(expected: ('ERC1155: invalid token ID', ))]
// fn test__transfer_nonexistent() {
//     ERC1155::_transfer(ZERO(), RECIPIENT(), TOKEN_ID());
// }

// #[test]
// #[available_gas(2000000)]
// #[should_panic(expected: ('ERC1155: invalid receiver', ))]
// fn test__transfer_to_zero() {
//     setup();

//     ERC1155::_transfer(OWNER(), ZERO(), TOKEN_ID());
// }

// #[test]
// #[available_gas(2000000)]
// #[should_panic(expected: ('ERC1155: wrong sender', ))]
// fn test__transfer_from_invalid_owner() {
//     setup();

//     ERC1155::_transfer(RECIPIENT(), OWNER(), TOKEN_ID());
// }

// ///
// /// Mint
// ///

// #[test]
// #[available_gas(2000000)]
// fn test__mint() {
//     assert(ERC1155::balance_of(RECIPIENT()) == 0.into(), 'Balance of recipient before');

//     ERC1155::_mint(RECIPIENT(), TOKEN_ID());

//     assert(ERC1155::owner_of(TOKEN_ID()) == RECIPIENT(), 'Ownership after');
//     assert(ERC1155::balance_of(RECIPIENT()) == 1.into(), 'Balance of recipient after');
//     assert(ERC1155::get_approved(TOKEN_ID()) == ZERO(), 'Approval implicitly set');
// }

// #[test]
// #[available_gas(2000000)]
// #[should_panic(expected: ('ERC1155: invalid receiver', ))]
// fn test__mint_to_zero() {
//     ERC1155::_mint(ZERO(), TOKEN_ID());
// }

// #[test]
// #[available_gas(2000000)]
// #[should_panic(expected: ('ERC1155: token already minted', ))]
// fn test__mint_already_exist() {
//     setup();

//     ERC1155::_mint(RECIPIENT(), TOKEN_ID());
// }

// ///
// /// Burn
// ///

// #[test]
// #[available_gas(2000000)]
// fn test__burn() {
//     setup();

//     ERC1155::_approve(OTHER(), TOKEN_ID());

//     assert(ERC1155::owner_of(TOKEN_ID()) == OWNER(), 'Ownership before');
//     assert(ERC1155::balance_of(OWNER()) == 1.into(), 'Balance of owner before');
//     assert(ERC1155::get_approved(TOKEN_ID()) == OTHER(), 'Approval before');

//     ERC1155::_burn(TOKEN_ID());

//     assert(ERC1155::_owners::read(TOKEN_ID()) == ZERO(), 'Ownership after');
//     assert(ERC1155::balance_of(OWNER()) == 0.into(), 'Balance of owner after');
//     assert(ERC1155::_token_approvals::read(TOKEN_ID()) == ZERO(), 'Approval after');
// }

// #[test]
// #[available_gas(2000000)]
// #[should_panic(expected: ('ERC1155: invalid token ID', ))]
// fn test__burn_nonexistent() {
//     ERC1155::_burn(TOKEN_ID());
// }

// ///
// /// _set_token_uri
// ///

// #[test]
// #[available_gas(2000000)]
// fn test__set_token_uri() {
//     setup();

//     assert(ERC1155::token_uri(TOKEN_ID()) == 0, 'URI should be 0');
//     ERC1155::_set_token_uri(TOKEN_ID(), URI);
//     assert(ERC1155::token_uri(TOKEN_ID()) == URI, 'URI should be set');
// }

// #[test]
// #[available_gas(2000000)]
// #[should_panic(expected: ('ERC1155: invalid token ID', ))]
// fn test__set_token_uri_nonexistent() {
//     ERC1155::_set_token_uri(TOKEN_ID(), URI);
// }
