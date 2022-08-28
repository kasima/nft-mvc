    object "721" {
        code {
            // Store the creator in slot zero.
            sstore(0, caller())

            // Deploy the contract
            datacopy(0, dataoffset("runtime"), datasize("runtime"))
            return(0, datasize("runtime"))
        }
        object "runtime" {
            code {
                // Protection against sending Ether
                require(iszero(callvalue()))
                
                // external function declaration
                switch selector()
                case 0x70a08231 /* "balanceOf(address)" */ {
                    returnUint(balanceOf(decodeAsAddress(0)))
                }
                case 0x6352211e /* ownerOf(uint256)  */ {
                    returnUint(ownerOf(decodeAsUint(0))) // treat the address as uint from interface
                }
                case 0x23b872dd /* transferFrom(address,address,uint256)  */ {
                    transferFrom(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2))
                }
                case 0x40c10f19 /*mint(address,uint256)*/ {
                    mint(decodeAsAddress(0), decodeAsUint(1))
                }
                case 0x095ea7b3 /* approve(address,uint256)  */ {
                    approve(decodeAsAddress(0), decodeAsUint(1))
                }
                case 0xa22cb465 /* setApprovalForAll(address, bool)  */ {
                    setApprovalForAll(decodeAsAddress(0), decodeAsBool(1))
                }
                case 0x081812fc /* getApproved(uint256)  */ {
                    returnUint(getApproved(decodeAsUint(0)))
                }
                case 0x3a95ab7f /*isApprovedForAll(address, address)*/ {
                    returnUint(isApprovedForAll(decodeAsAddress(0), decodeAsAddress(1)))
                }
                default{
                    revert(0,0)
                }

                /* ---------- calldata decoding functions ----------- */
                function selector() -> s {
                    // this function will fetch the first 4 bytes
                    // effectively divide by 28 bytes
                    // calldataload loads 32 bytes total
                    s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
                }

                // fetch and return a function argument in position <offset> index
                function decodeAsAddress(offset) -> v {
                    // v is a word- 256bits
                    v := decodeAsUint(offset)
                    // ethereum addresses are 20 bytes, we remove 0xffff.. which leaves us with 20 bytes address
                    // not 0xfff.. is 160 bits, all ethereum addresses are 160 bits
                    // condition checks that a word is 160 bits size
                    if iszero(iszero(and(v, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
                        revert(0, 0)
                    }
                }

                function decodeAsBool(offset) -> v {
                    v := decodeAsUint(offset)
                    if not(or(eq(1, v), eq(0, v))) {
                        revert(0, 0)
                    }
                }

                // fetch and return a function argument in position <offset> index
                function decodeAsUint(offset) -> v {
                    // get the first position that is the first 4 bytes + (index * 0x20)
                    // 0x10 = 16, each slot is 32 bytes hence 0x20
                    let pos := add(4, mul(offset, 0x20))
                    // if size of call data is less than a word in position + 1 word, revert
                    // to verify that the position + argument is not longer that total calldata
                    // before loading 32 bytes
                    if lt(calldatasize(), add(pos, 0x20)) {
                        revert(0, 0)
                    }
                    // load 32 bytes at a position
                    v := calldataload(pos)
                }

                /* ---------- calldata encoding/decoding functions ---------- */
                // store in memory and return uint256 value immediately
                function returnUint(v) {
                    mstore(0, v)
                    return(0, 0x20)
                }

                function returnTrue() {
                    returnUint(1)
                }

                /* ---------- utility functions ---------- */
                function validAddress(v) {
                    if iszero(iszero(and(v, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
                        revert(0, 0)
                    }
                }

                function validBool(v) {
                    if not(or(eq(1, v), eq(0, v))) {
                        revert(0, 0)
                    }
                }

                function lte(a, b) -> r {
                    r := iszero(gt(a, b))
                }
                function gte(a, b) -> r {
                    r := iszero(lt(a, b))
                }
                function safeAdd(a, b) -> r {
                    r := add(a, b)
                    if or(lt(r, a), lt(r, b)) { revert(0, 0) }
                }

                function safeSub(a, b) -> r {
                    r := sub(a, b)
                    if or(gt(r, a), gt(b, a)) { revert(0, 0) }
                }

                function require(condition) {
                    if iszero(condition) { revert(0, 0) }
                }

                function inc(v) -> r {
                    r := safeAdd(v,1)
                }

                function dec(v) -> r {
                    r := safeSub(v,1)
                }

                /* ----------- events ----------- */

                // EIP721 requires 3 indexes for Approve and Transfer events
                function emitEvent4(signatureHash, indexed1, indexed2, indexed3) {
                    // no unindexed field to be logged
                    log4(0, 0, signatureHash, indexed1, indexed2, indexed3)
                }

                // use only for ApproveAll() events
                // nonIndexed is part of an event but must instead be read from memory
                // found in the data field
                function emitEvent3(signatureHash, indexed1, indexed2, nonIndexed) {
                    mstore(0, nonIndexed)
                    log3(0, 0x20, signatureHash, indexed1, indexed2)
                }

                function emitTransfer(from, to, tokenId) {
                    let signatureHash := 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
                    emitEvent4(signatureHash, from, to, tokenId)
                }

                function emitApproval(_owner, approved, tokenId) {
                    let signatureHash := 0x6e11fb1b7f119e3f2fa29896ef5fdf8b8a2d0d4df6fe90ba8668e7d8b2ffa25e
                    emitEvent4(signatureHash, _owner, approved, tokenId)
                }

                function emitApproveForAll(_owner, operator, approved) {
                    let signatureHash := 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31
                    emitEvent3(signatureHash, _owner, operator, approved)
                }

                /* -------- helpers for storage access ---------- */

                // basic storage map getter
                function getStorageAt(key, slot) -> addr {
                    // Store num in memory scratch space
                    mstore(0, key)
                    mstore(0x20, slot)
                    // Create hash from previously stored num and slot
                    let hash := keccak256(0, 0x40)
                    // Load mapping value using the just calculated hash
                    addr := sload(hash)
                }

                // basic storage map setter
                function setStorageAt(key, value, slot) {
                    mstore(0, key)
                    mstore(0x20, slot)
                    let hash := keccak256(0, 0x40)
                    sstore(hash, value)
                }

                /* ----------- contract storage position management ----------- */
                // SLOTS
                // fixed size slot
                function ownerPos() -> p { p := 0 }

                // mapping slot offset
                function tokenOwnerPos() -> p { p := 1 }
                function accountBalancePos() -> p { p := 2 }
                function tokenApprovalsPos() -> p { p := 3 }
                function operatorApprovalPos() -> p { p := 4 }

                function owner() -> o {
                    o := sload(ownerPos())
                }

                function _owners(tokenId) -> os {
                    os := getStorageAt(tokenId, tokenOwnerPos())
                }

                function _balances(_of) -> b {
                    b := getStorageAt(_of, accountBalancePos())
                }

                function _approvals(tokenId) -> a {
                    a := getStorageAt(tokenId, tokenApprovalsPos())
                }

                function _operatorApprovals(_owner, _operator) -> oa {
                    // Store num in memory scratch space
                    mstore(0, _owner)
                    mstore(0x20, _operator)
                    mstore(0x40, operatorApprovalPos())
                    // Create hash from the two inputs and slot
                    let hash := keccak256(0, 0x60)
                    // Load mapping value using the just calculated hash
                    oa := sload(hash)
                }

                function _setOperatorApprovals(_owner, _operator, _b) {
                    // boolean check
                    validBool(_b)
                    // Store num in memory scratch space
                    mstore(0, _owner)
                    mstore(0x20, _operator)
                    mstore(0x40, operatorApprovalPos())
                    // Create hash from the two inputs and slot
                    let hash := keccak256(0, 0x60)
                    // sload mapping value using the just calculated hash
                    sstore(hash, _b)
                }

                /* ----------- internal util function ----------- */
                function _mint(_for, _tokenId) {
                    // TODO check that token is not minted already
                    let cb := _balances(_for)
                    setStorageAt(_for, inc(cb), accountBalancePos())
                    setStorageAt(_tokenId, _for, tokenOwnerPos())
                }

                // 
                function _transfer(from, to, tokenId) {
                    // require(and(eq(_owners(id), from), eq(from, caller())))
                    let currentFromBal := _balances(from)
                    let currentToBal := _balances(to)
                    setStorageAt(from, dec(currentFromBal), accountBalancePos())
                    setStorageAt(to, inc(currentToBal), accountBalancePos())
                    setStorageAt(tokenId, to, tokenOwnerPos())
                    emitTransfer(from, to, tokenId)
                }

                function _approve(to, tokenId) {
                    setStorageAt(tokenId, to, tokenApprovalsPos())
                    emitApproval(_owners(tokenId), to, tokenId)
                }

                /* ----------- private interface functions ----------- */

                function balanceOf(_owner) -> bal {
                    // address check
                    validAddress(_owner)
                    bal := _balances(_owner)
                }

                function ownerOf(tokenId) -> own {
                    own := _owners(tokenId)
                }

                /// @dev Throws unless `msg.sender` is the current owner, an authorized
                ///  operator, or the approved address for this NFT. Throws if `_from` is
                ///  not the current owner. Throws if `_to` is the zero address. Throws if
                ///  `_tokenId` is not a valid NFT.
                function transferFrom(_from, _to, _tokenId) {
                    validAddress(_from)
                    validAddress(_to)
                    let isOwner := and(eq(_owners(_tokenId), _from), eq(_from, caller())) // caller, owner check
                    let isOperator := eq(1, _operatorApprovals(_from, caller()))// operator check
                    let isApproved := eq(caller(), _approvals(_tokenId))// approval check
                    require(or(or(isApproved, isOperator), isOwner)) // either 1 case fails or reverts
                    require(not(iszero(_to))) // check non zero destination
                    require(not(iszero(_owners(_tokenId)))) // check existence of a token with owner existence
                    _transfer(_from, _to, _tokenId)
                }

                function setApprovalForAll(_operator, _approved) {
                    validAddress(_operator)
                    validAddress(_approved)
                    _setOperatorApprovals(caller(), _operator, _approved)
                }

                function approve(_approvedAddress, _tokenId) {
                    validAddress(_approvedAddress)
                    require(eq(caller(), _owners(_tokenId)))
                    _approve(_approvedAddress, _tokenId)
                }

                function getApproved(_tokenId) -> a {
                    a := _approvals(_tokenId)
                }

                function isApprovedForAll(_owner, _operator) -> b {
                    b := _operatorApprovals(_owner, _operator)
                }

                // @note: non standard EIP721 admin function
                function mint(_to, _tokenId) {
                    validAddress(_to)
                    require(eq(caller(), owner())) // caller is owner
                    require(not(iszero(_owners(_tokenId)))) // owner of id don't already exists
                    _mint(_to, _tokenId)
                } 
            }
        }
    }