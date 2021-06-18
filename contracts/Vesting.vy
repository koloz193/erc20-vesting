from vyper.interfaces import ERC20
from . import IVesting

implements: IVesting

SECONDS_PER_MONTH: constant(uint256) = 2628000

event GrantAdded:
      recipient: indexed(address)
      start: uint256
      amount: uint256
      duration: uint256
      cliff: uint256

struct Grant:
       start: uint256
       amount: uint256
       duration: uint256
       cliff: uint256
       monthsClaimed: uint256
       totalClaimed: uint256

token: public(ERC20)
owner: public(address)
tokenGrants: public(HashMap[address, Grant])

@external
@nonpayable
def __init__(_token: address):
    assert _token != ZERO_ADDRESS, "init::cant set token to zero address"
    self.owner = msg.sender
    self.token = ERC20(_token)

@external
@nonpayable
def addTokenGrant(_recipient: address, _start: uint256, _amount: uint256, _totalDuration: uint256, _cliff: uint256):
    assert msg.sender == self.owner, "addTokenGrant::only owner can add a grant"
    assert self.tokenGrants[msg.sender] == empty(Grant), "addTokenGrant::address already has an active grant"
    assert _totalDuration > _cliff, "addTokenGrant::duration must be longer than cliff"
    amtPerMonth: uint256 = _amount / _totalDuration
    assert amtPerMonth > 0, "addTokenGrant::amount per month must be greater than 0"

    start: uint256 = 0

    if _start == 0:
       start = block.timestamp
    else:
        start = _start

    self.tokenGrants[msg.sender] = Grant({
                     start: start,
                     amount: _amount,
                     duration: _totalDuration,
                     cliff: _cliff,
                     monthsClaimed: 0,
                     totalClaimed: 0
    })

    log GrantAdded(msg.sender, start, _amount, _totalDuration, _cliff)

@external
@nonpayable
def removeTokenGrant(_recipient: address):
    pass

@external
@nonpayable
def claimVestedTokens():
    pass

@internal
@view
def calculateGrantClaim() -> (uint256, uint256):
    return (0, 0)
