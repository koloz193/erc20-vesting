interface IVesting:
	  def addTokenGrant(_recipient: address, _startTime: address, _amount: uint256, _vestingDuration: uint256, _vestingCliff: uint256): nonpayable
	  def removeTokenGrant(_recipient: address): nonpayable
	  def claimVestedTokens(): nonpayable
	  def calculateGrantClaim() -> (uint256, uint256): view
