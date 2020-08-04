pragma solidity ^0.5.16;

// Internal References
import "./interfaces/IAddressResolver.sol";
import "./interfaces/IFlexibleStorage.sol";


// https://docs.synthetix.io/contracts/source/contracts/FlexibleStorage
contract FlexibleStorage is IFlexibleStorage {
    IAddressResolver public resolverProxy;

    mapping(bytes32 => bytes32) public hashes;

    mapping(bytes32 => mapping(bytes32 => uint)) internal uintStorage;
    mapping(bytes32 => mapping(bytes32 => address)) internal addressStorage;
    mapping(bytes32 => mapping(bytes32 => bool)) internal boolStorage;

    // mapping(bytes32 => string) internal StringStorage;
    // mapping(bytes32 => bytes) internal BytesStorage;
    // mapping(bytes32 => bytes32) internal Bytes32Storage;
    // mapping(bytes32 => int) internal IntStorage;

    constructor(address _resolver) public {
        // ReadProxyAddressResolver
        resolverProxy = IAddressResolver(_resolver);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _memoizeHash(bytes32 contractName) internal returns (bytes32) {
        if (hashes[contractName] == bytes32(0)) {
            // set to unique hash at the time of creation
            hashes[contractName] = keccak256(abi.encodePacked(msg.sender, contractName, block.number));
        }
        return hashes[contractName];
    }

    function _setUIntValue(
        bytes32 contractName,
        bytes32 record,
        uint value
    ) internal {
        uintStorage[_memoizeHash(contractName)][record] = value;
        emit ValueSetUInt(contractName, record, value);
    }

    function _setAddressValue(
        bytes32 contractName,
        bytes32 record,
        address value
    ) internal {
        addressStorage[_memoizeHash(contractName)][record] = value;
        emit ValueSetAddress(contractName, record, value);
    }

    function _setBoolValue(
        bytes32 contractName,
        bytes32 record,
        bool value
    ) internal {
        boolStorage[_memoizeHash(contractName)][record] = value;
        emit ValueSetBool(contractName, record, value);
    }

    /* ========== VIEWS ========== */

    function getUIntValue(bytes32 contractName, bytes32 record) external view returns (uint) {
        return uintStorage[hashes[contractName]][record];
    }

    function getUIntValues(bytes32 contractName, bytes32[] calldata records) external view returns (uint[] memory) {
        uint[] memory results = new uint[](records.length);

        mapping(bytes32 => uint) storage data = uintStorage[hashes[contractName]];
        for (uint i = 0; i < records.length; i++) {
            results[i] = data[records[i]];
        }
        return results;
    }

    function getAddressValue(bytes32 contractName, bytes32 record) external view returns (address) {
        return addressStorage[hashes[contractName]][record];
    }

    function getAddressValues(bytes32 contractName, bytes32[] calldata records) external view returns (address[] memory) {
        address[] memory results = new address[](records.length);

        mapping(bytes32 => address) storage data = addressStorage[hashes[contractName]];
        for (uint i = 0; i < records.length; i++) {
            results[i] = data[records[i]];
        }
        return results;
    }

    function getBoolValue(bytes32 contractName, bytes32 record) external view returns (bool) {
        return boolStorage[hashes[contractName]][record];
    }

    function getBoolValues(bytes32 contractName, bytes32[] calldata records) external view returns (bool[] memory) {
        bool[] memory results = new bool[](records.length);

        mapping(bytes32 => bool) storage data = boolStorage[hashes[contractName]];
        for (uint i = 0; i < records.length; i++) {
            results[i] = data[records[i]];
        }
        return results;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setUIntValue(
        bytes32 contractName,
        bytes32 record,
        uint value
    ) external onlyContract(contractName) {
        _setUIntValue(contractName, record, value);
    }

    function setUIntValues(
        bytes32 contractName,
        bytes32[] calldata records,
        uint[] calldata values
    ) external onlyContract(contractName) {
        require(records.length == values.length, "Input lengths must match");

        for (uint i = 0; i < records.length; i++) {
            _setUIntValue(contractName, records[i], values[i]);
        }
    }

    function deleteUIntValue(bytes32 contractName, bytes32 record) external onlyContract(contractName) {
        delete uintStorage[hashes[contractName]][record];
        emit ValueDeleted(contractName, record);
    }

    function setAddressValue(
        bytes32 contractName,
        bytes32 record,
        address value
    ) external onlyContract(contractName) {
        _setAddressValue(contractName, record, value);
    }

    function setAddressValues(
        bytes32 contractName,
        bytes32[] calldata records,
        address[] calldata values
    ) external onlyContract(contractName) {
        require(records.length == values.length, "Input lengths must match");

        for (uint i = 0; i < records.length; i++) {
            _setAddressValue(contractName, records[i], values[i]);
        }
    }

    function deleteAddressValue(bytes32 contractName, bytes32 record) external onlyContract(contractName) {
        delete addressStorage[hashes[contractName]][record];
        emit ValueDeleted(contractName, record);
    }

    function setBoolValue(
        bytes32 contractName,
        bytes32 record,
        bool value
    ) external onlyContract(contractName) {
        _setBoolValue(contractName, record, value);
    }

    function setBoolValues(
        bytes32 contractName,
        bytes32[] calldata records,
        bool[] calldata values
    ) external onlyContract(contractName) {
        require(records.length == values.length, "Input lengths must match");

        for (uint i = 0; i < records.length; i++) {
            _setBoolValue(contractName, records[i], values[i]);
        }
    }

    function deleteBoolValue(bytes32 contractName, bytes32 record) external onlyContract(contractName) {
        delete boolStorage[hashes[contractName]][record];
        emit ValueDeleted(contractName, record);
    }

    function migrateContractKey(
        bytes32 fromContractName,
        bytes32 toContractName,
        bool removeAccessFromPreviousContract
    ) external onlyContract(fromContractName) {
        require(hashes[fromContractName] != bytes32(0), "Cannot migrate empty contract");

        hashes[toContractName] = hashes[fromContractName];

        if (removeAccessFromPreviousContract) {
            delete hashes[fromContractName];
        }

        emit KeyMigrated(fromContractName, toContractName, removeAccessFromPreviousContract);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyContract(bytes32 contractName) {
        address callingContract = resolverProxy.requireAndGetAddress(
            contractName,
            "Cannot find contract in Address Resolver"
        );
        require(callingContract == msg.sender, "Can only be invoked by the configured contract");
        _;
    }

    /* ========== EVENTS ========== */

    event ValueSetUInt(bytes32 contractName, bytes32 record, uint value);
    event ValueSetAddress(bytes32 contractName, bytes32 record, address value);
    event ValueSetBool(bytes32 contractName, bytes32 record, bool value);
    event ValueDeleted(bytes32 contractName, bytes32 record);
    event KeyMigrated(bytes32 fromContractName, bytes32 toContractName, bool removeAccessFromPreviousContract);
}
