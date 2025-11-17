# @version ^0.3.10

owner: public(address)
records: public(HashMap[address, String[128]])

@external
def __init__():
    self.owner = msg.sender

@external
def set_record(addr: address, record: String[128]):
    assert msg.sender == self.owner, "Only owner"
    self.records[addr] = record

@view
@external
def get_record(addr: address) -> String[128]:
    return self.records[addr]
