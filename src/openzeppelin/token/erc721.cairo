use serde::Serde;
use starknet::ContractAddress;
use starknet::contract_address::ContractAddressSerde;
use array::ArrayTrait;

const IERC721_ID: felt252 = 0x80ac58cd;
const IERC721METADATA_ID: felt252 = 0x5b5e139f;
const IERC721_RECEIVER_ID: felt252 = 0x150b7a02;

/// TODO:
// - IERC721 should inherit IERC165
// - We should have IERC721Metadata that inherit IERC721
// - name(), symbol() and token_uri(u256) should be in IERC721Metadata, not in iERC721
#[abi]
trait IERC721 {
    // IERC721Metadata
    fn name() -> felt252;
    fn symbol() -> felt252;
    fn token_uri(tokenId: u256) -> felt252;
    // IERC721
    fn balance_of(owner: ContractAddress) -> u256;
    fn owner_of(tokenId: u256) -> ContractAddress;
    fn transfer_from(from: ContractAddress, to: ContractAddress, tokenId: u256);
    fn safe_transfer_from(
        from: ContractAddress, to: ContractAddress, tokenId: u256, data: Array<felt252>
    );
    fn approve(approved: ContractAddress, tokenId: u256);
    fn set_approval_for_all(operator: ContractAddress, approved: bool);
    fn get_approved(tokenId: u256) -> ContractAddress;
    fn is_approved_for_all(owner: ContractAddress, operator: ContractAddress) -> bool;
}

#[abi]
trait IERC721Receiver {
    fn on_erc721_received(
        operator: ContractAddress, from: ContractAddress, tokenId: u256, data: Array<felt252>
    ) -> felt252;
}

#[contract]
mod ERC721 {
    // OZ modules
    use openzeppelin::account;
    use openzeppelin::introspection::erc165;
    use openzeppelin::token::erc721;

    // Dispatchers
    use openzeppelin::introspection::erc165::IERC165Dispatcher;
    use openzeppelin::introspection::erc165::IERC165DispatcherTrait;
    use super::IERC721ReceiverDispatcher;
    use super::IERC721ReceiverDispatcherTrait;

    // Other
    use super::ArrayTrait;
    use super::ContractAddress;
    use starknet::contract_address_const;
    use starknet::contract_address::ContractAddressPartialEq;
    use starknet::ContractAddressZeroable;
    use starknet::get_caller_address;
    use integer::u256_from_felt252;
    use traits::Into;
    use option::Option;
    use option::OptionTrait;
    use zeroable::Zeroable;

    struct Storage {
        _name: felt252,
        _symbol: felt252,
        _owners: LegacyMap<u256, ContractAddress>,
        _balances: LegacyMap<ContractAddress, u256>,
        _token_approvals: LegacyMap<u256, ContractAddress>,
        _operator_approvals: LegacyMap<(ContractAddress, ContractAddress), bool>,
        _token_uri: LegacyMap<u256, felt252>,
    }

    #[event]
    fn Transfer(from: ContractAddress, to: ContractAddress, token_id: u256) {}

    #[event]
    fn Approval(owner: ContractAddress, approved: ContractAddress, token_id: u256) {}

    #[event]
    fn ApprovalForAll(owner: ContractAddress, operator: ContractAddress, approved: bool) {}

    #[constructor]
    fn constructor(name: felt252, symbol: felt252) {
        initializer(name, symbol);
    }

    impl ERC721 of erc721::IERC721 {
        // IERC721Metadata
        fn name() -> felt252 {
            _name::read()
        }

        fn symbol() -> felt252 {
            _symbol::read()
        }

        fn token_uri(token_id: u256) -> felt252 {
            assert(_exists(token_id), 'ERC721: invalid token ID');
            _token_uri::read(token_id)
        }

        // IERC721
        fn balance_of(account: ContractAddress) -> u256 {
            assert(!account.is_zero(), 'ERC721: invalid holder');
            _balances::read(account)
        }

        fn owner_of(token_id: u256) -> ContractAddress {
            let owner = _owner(token_id);
            assert(owner.is_some(), 'ERC721: invalid token ID');
            owner.unwrap()
        }

        fn get_approved(token_id: u256) -> ContractAddress {
            assert(_exists(token_id), 'ERC721: invalid token ID');
            _token_approvals::read(token_id)
        }

        fn is_approved_for_all(owner: ContractAddress, operator: ContractAddress) -> bool {
            _operator_approvals::read((owner, operator))
        }

        fn approve(to: ContractAddress, token_id: u256) {
            let owner = _owner(token_id);
            assert(owner.is_some(), 'ERC721: invalid token ID');

            let caller = get_caller_address();
            assert(
                owner.unwrap() == caller | is_approved_for_all(owner.unwrap(), caller),
                'ERC721: unauthorized caller'
            );
            _approve(to, token_id)
        }

        fn set_approval_for_all(operator: ContractAddress, approved: bool) {
            _set_approval_for_all(get_caller_address(), operator, approved)
        }

        fn transfer_from(from: ContractAddress, to: ContractAddress, token_id: u256) {
            assert(
                _is_approved_or_owner(get_caller_address(), token_id),
                'ERC721: unauthorized transfer'
            );
            _transfer(from, to, token_id);
        }

        fn safe_transfer_from(
            from: ContractAddress, to: ContractAddress, token_id: u256, data: Array<felt252>
        ) {
            assert(
                _is_approved_or_owner(get_caller_address(), token_id),
                'ERC721: unauthorized transfer'
            );
            _safe_transfer(from, to, token_id, data);
        }
    }

    #[view]
    fn supports_interface(interface_id: felt252) -> bool {
        erc165::ERC165Contract::supports_interface(interface_id)
    }

    #[view]
    fn name() -> felt252 {
        ERC721::name()
    }

    #[view]
    fn symbol() -> felt252 {
        ERC721::symbol()
    }

    #[view]
    fn token_uri(token_id: u256) -> felt252 {
        ERC721::token_uri(token_id)
    }

    #[view]
    fn balance_of(account: ContractAddress) -> u256 {
        ERC721::balance_of(account)
    }

    #[view]
    fn owner_of(token_id: u256) -> ContractAddress {
        ERC721::owner_of(token_id)
    }

    #[view]
    fn get_approved(token_id: u256) -> ContractAddress {
        ERC721::get_approved(token_id)
    }

    #[view]
    fn is_approved_for_all(owner: ContractAddress, operator: ContractAddress) -> bool {
        ERC721::is_approved_for_all(owner, operator)
    }

    #[external]
    fn approve(to: ContractAddress, token_id: u256) {
        ERC721::approve(to, token_id)
    }

    #[external]
    fn set_approval_for_all(operator: ContractAddress, approved: bool) {
        ERC721::set_approval_for_all(operator, approved)
    }

    #[external]
    fn transfer_from(from: ContractAddress, to: ContractAddress, token_id: u256) {
        ERC721::transfer_from(from, to, token_id)
    }

    #[external]
    fn safe_transfer_from(
        from: ContractAddress, to: ContractAddress, token_id: u256, data: Array<felt252>
    ) {
        ERC721::safe_transfer_from(from, to, token_id, data)
    }

    #[internal]
    fn initializer(name_: felt252, symbol_: felt252) {
        _name::write(name_);
        _symbol::write(symbol_);
        erc165::ERC165Contract::register_interface(erc721::IERC721_ID);
        erc165::ERC165Contract::register_interface(erc721::IERC721METADATA_ID);
    }

    #[internal]
    fn _owner(token_id: u256) -> Option<ContractAddress> {
        let owner = _owners::read(token_id);
        match owner.is_zero() {
            bool::False(()) => Option::Some(owner),
            bool::True(()) => Option::None(())
        }
    }

    #[internal]
    fn _exists(token_id: u256) -> bool {
        !_owners::read(token_id).is_zero()
    }

    #[internal]
    fn _is_approved_or_owner(spender: ContractAddress, token_id: u256) -> bool {
        let owner = _owner(token_id);
        assert(owner.is_some(), 'ERC721: invalid token ID');
        owner.unwrap() == spender | is_approved_for_all(
            owner.unwrap(), spender
        ) | spender == get_approved(token_id)
    }

    #[internal]
    fn _approve(to: ContractAddress, token_id: u256) {
        let owner = _owner(token_id);
        assert(owner.is_some(), 'ERC721: invalid token ID');
        _token_approvals::write(token_id, to);
        Approval(owner.unwrap(), to, token_id);
    }

    #[internal]
    fn _set_approval_for_all(owner: ContractAddress, operator: ContractAddress, approved: bool) {
        assert(owner != operator, 'ERC721: approve to caller');
        _operator_approvals::write((owner, operator), approved);
        ApprovalForAll(owner, operator, approved);
    }

    #[internal]
    fn _mint(to: ContractAddress, token_id: u256) {
        let owner = _owner(token_id);
        assert(owner.is_none(), 'ERC721 token already minted');

        assert(!to.is_zero(), 'ERC721: invalid receiver');

        // Update balances
        _balances::write(to, _balances::read(to) + u256_from_felt252(1));

        // Update token_id owner
        _owners::write(token_id, to);

        // Emit event
        Transfer(contract_address_const::<0>(), to, token_id);
    }

    #[internal]
    fn _transfer(from: ContractAddress, to: ContractAddress, token_id: u256) {
        let owner = _owner(token_id);
        assert(owner.is_some(), 'ERC721: invalid token ID');

        assert(from == owner.unwrap(), 'ERC721: wrong sender');
        assert(!to.is_zero(), 'ERC721: invalid receiver');

        // Implicit clear approvals, no need to emit an event
        _token_approvals::write(token_id, contract_address_const::<0>());

        // Update balances
        _balances::write(from, _balances::read(from) - u256_from_felt252(1));
        _balances::write(to, _balances::read(to) + u256_from_felt252(1));

        // Update token_id owner
        _owners::write(token_id, to);

        // Emit event
        Transfer(from, to, token_id);
    }

    #[internal]
    fn _burn(token_id: u256) {
        let owner = _owner(token_id);
        assert(owner.is_some(), 'ERC721: invalid token ID');

        // Implicit clear approvals, no need to emit an event
        _token_approvals::write(token_id, contract_address_const::<0>());

        // Update balances
        _balances::write(owner.unwrap(), _balances::read(owner.unwrap()) - u256_from_felt252(1));

        // Delete owner
        _owners::write(token_id, contract_address_const::<0>());

        // Emit event
        Transfer(owner.unwrap(), contract_address_const::<0>(), token_id);
    }

    #[internal]
    fn _safe_mint(to: ContractAddress, token_id: u256, data: Array<felt252>) {
        _mint(to, token_id);
        assert(
            _check_on_erc721_received(contract_address_const::<0>(), to, token_id, data),
            'ERC721: safe mint failed'
        );
    }

    #[internal]
    fn _safe_transfer(
        from: ContractAddress, to: ContractAddress, token_id: u256, data: Array<felt252>
    ) {
        _transfer(from, to, token_id);
        assert(_check_on_erc721_received(from, to, token_id, data), 'ERC721: safe transfer failed');
    }

    #[internal]
    fn _set_token_uri(token_id: u256, token_uri: felt252) {
        assert(_exists(token_id), 'ERC721: invalid token ID');
        _token_uri::write(token_id, token_uri)
    }

    #[private]
    fn _check_on_erc721_received(
        from: ContractAddress, to: ContractAddress, token_id: u256, data: Array<felt252>
    ) -> bool {
        if (IERC165Dispatcher {
            contract_address: to
        }.supports_interface(
            erc721::IERC721_RECEIVER_ID
        )) {
            assert(
                IERC721ReceiverDispatcher {
                    contract_address: to
                }.on_erc721_received(
                    get_caller_address(), from, token_id, data
                ) == erc721::IERC721_RECEIVER_ID,
                'ERC721: on_eRC721_receiver fail'
            );
            return true;
        }
        IERC165Dispatcher { contract_address: to }.supports_interface(account::ACCOUNT_ID)
    }
}
