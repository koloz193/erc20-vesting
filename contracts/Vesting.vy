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

event TokensClaimed:
      recipient: indexed(address)
      amountClaimed: uint256

event GrantRemoved:
      recipient: indexed(address)
      amtVested: uint256
      amtNotVested: uint256

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

@internal
@view
def calculateGrantClaim(_recipient: address) -> (uint256, uint256):
    grant: Grant = self.tokenGrants[_recipient]

    if block.timestamp < grant.start:
       return (0, 0)

    timePassed: uint256 = block.timestamp - grant.start
    monthsPassed: uint256 = timePassed / SECONDS_PER_MONTH

    if monthsPassed < grant.cliff:
       return (0, 0)

    if monthsPassed >= grant.duration:
        remaining: uint256 = grant.amount - grant.totalClaimed
        return (grant.duration, remaining)
    else:
        monthsVested: uint256 = monthsPassed - grant.monthsClaimed
        monthlyVestAmt: uint256 = grant.amount / grant.duration
        amtVested: uint256 = monthsVested * monthlyVestAmt
        return (monthsVested, amtVested)

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
    grant: Grant = self.tokenGrants[_recipient]

    monthsVested: uint256 = 0
    amtVested: uint256 = 0

    (monthsVested, amtVested) = self.calculateGrantClaim(_recipient)
    amtNotVested: uint256 = grant.amount - grant.totalClaimed - amtVested

    self.token.transfer(_recipient, amtVested)
    self.token.transfer(self.owner, amtNotVested)

    self.tokenGrants[_recipient] = empty(Grant)

    log GrantRemoved(_recipient, amtVested, amtNotVested)

@external
@nonpayable
def claimVestedTokens():
    monthsVested: uint256 = 0
    amtVested: uint256 = 0

    (monthsVested, amtVested) = self.calculateGrantClaim(msg.sender)
    assert amtVested > 0, "claimVestedTokens::no tokens available to claim"

    grant: Grant = self.tokenGrants[msg.sender]
    grant.monthsClaimed = grant.monthsClaimed + monthsVested
    grant.totalClaimed = grant.totalClaimed + amtVested

    self.token.transfer(msg.sender, amtVested)
    log TokensClaimed(msg.sender, amtVested)
