greeting: String[100]

@external
def __init__(_greeting: String[100]):
    self.greeting = _greeting

@view
@external
def greet() -> String[100]:
    return self.greeting

@external
def setGreeting(_greeting: String[100]):
    self.greeting = _greeting
