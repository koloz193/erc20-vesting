interface IERC20:
	  def name() -> String[64]: view
	  def symbol() -> String[8]: view
	  def decimals() -> uint8: view
	  def totalSupply() -> uint256: view