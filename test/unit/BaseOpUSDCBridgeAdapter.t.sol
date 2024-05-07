// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BaseOpUSDCBridgeAdapter, IOpUSDCBridgeAdapter} from 'contracts/BaseOpUSDCBridgeAdapter.sol';
import {StdStorage, Test, stdStorage} from 'forge-std/Test.sol';

contract TestOpUSDCBridgeAdapter is BaseOpUSDCBridgeAdapter {
  constructor(address _USDC, address _messenger) BaseOpUSDCBridgeAdapter(_USDC, _messenger) {}

  function send(bool _isCanonical, uint256 _amount, uint32 _minGasLimit) external override {}

  function receiveMessage(address _user, uint256 _amount) external override {}
}

abstract contract Base is Test {
  TestOpUSDCBridgeAdapter public adapter;

  address internal _owner = makeAddr('owner');
  address internal _USDC = makeAddr('opUSDC');
  address internal _messenger = makeAddr('messenger');

  event LinkedAdapterSet(address linkedAdapter);

  function setUp() public virtual {
    vm.prank(_owner);
    adapter = new TestOpUSDCBridgeAdapter(_USDC, _messenger);
  }
}

contract UnitInitialization is Base {
  function testInitialization() public {
    assertEq(adapter.USDC(), _USDC, 'USDC should be set to the provided address');
    assertEq(adapter.MESSENGER(), _messenger, 'Messenger should be set to the provided address');
    assertEq(adapter.linkedAdapter(), address(0), 'Linked adapter should be initialized to 0');
    assertEq(adapter.owner(), _owner, 'Owner should be set to the deployer');
  }

  function testLinkedAdapter() public {
    address _linkedAdapter = makeAddr('linkedAdapter');

    vm.prank(_owner);
    adapter.setLinkedAdapter(_linkedAdapter);
    assertEq(adapter.linkedAdapter(), _linkedAdapter, 'Linked adapter should be set to the new adapter');
  }

  function testSetLinkedAdapterEmitsEvent() public {
    address _linkedAdapter = makeAddr('linkedAdapter');

    vm.prank(_owner);
    vm.expectEmit(true, true, true, true);
    emit LinkedAdapterSet(_linkedAdapter);
    adapter.setLinkedAdapter(_linkedAdapter);
  }
}

contract UnitStopMessaging is Base {
  using stdStorage for StdStorage;

  function testStopMessaging() public {
    vm.mockCall(adapter.linkedAdapter(), abi.encodeWithSignature('receiveStopMessaging()'), abi.encode(''));
    vm.prank(_owner);
    adapter.stopMessaging();
    assertEq(adapter.isMessagingDisabled(), true, 'Messaging should be disabled');
  }

  function testReceiveStopMessaging() public {
    address _linkedAdapter = makeAddr('linkedAdapter');

    stdstore.target(address(adapter)).sig('linkedAdapter()').depth(0).checked_write(_linkedAdapter);
    vm.prank(_linkedAdapter);
    adapter.receiveStopMessaging();
    assertEq(adapter.isMessagingDisabled(), true, 'Messaging should be disabled');
  }

  function testReceiveStopMessagingWrongSender() public {
    address _linkedAdapter = makeAddr('linkedAdapter');
    address _notLinkedAdapter = makeAddr('notLinkedAdapter');

    stdstore.target(address(adapter)).sig('linkedAdapter()').depth(0).checked_write(_linkedAdapter);
    vm.prank(_notLinkedAdapter);
    vm.expectRevert(IOpUSDCBridgeAdapter.OpUSDCBridgeAdapter_NotLinkedAdapter.selector);
    adapter.receiveStopMessaging();
    assertEq(adapter.isMessagingDisabled(), false, 'Messaging should not be disabled');
  }
}
