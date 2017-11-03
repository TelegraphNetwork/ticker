pragma solidity ^0.4.16;

contract Owned {
    address public Owner;

    function Owned() internal {
        Owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == Owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        Owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract MyToken is Owned {
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;


    uint256 public preIco_start;
    uint256 public preIco_end;
    uint256 public preIco_tokensLimit;
    uint256 public preIco_price;
    uint256 public preIco_sold;

    uint256 public Ico_start;
    uint256 public Ico_end;
    uint256 public Ico_tokensLimit;
    uint256 public Ico_price;
    uint256 public Ico_sold;


    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);


    function MyToken() {
        decimals = 3;
        balanceOf[msg.sender] = 11000000*(10*decimals);
        totalSupply = 20000000*(10*decimals);
        name = "Zero Token";
        symbol = "ZRT";

        preIco_start=1509926400;
        preIco_end=1510444800;
        preIco_price=500000000*(10*decimals);
        preIco_tokensLimit=1000000*(10*decimals);
        preIco_sold=0;

        Ico_start=1511222400;
        Ico_end=1513814400;
        Ico_price=1000000000*(10*decimals);
        Ico_tokensLimit=totalSupply;
        Ico_sold=0;
    }


    function transfer(address _to, uint256 _value) {
        if (_to == 0x0) throw;
        if (balanceOf[msg.sender] < _value) throw;
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
    }


    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }


    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }


    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_to == 0x0) throw;                                // Prevent transfer to 0x0 address.
        if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;     // Check allowance
        balanceOf[_from] -= _value;                           // Subtract from the sender
        balanceOf[_to] += _value;                             // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }


    function buy() payable public {
        require(msg.value>0);
        uint256 current_price=0;
        uint256 amount=0;
        uint256 res_amount=0;
        uint limit=0;

        if (now >= preIco_start && now <= preIco_end) {
            // preIco stage
            current_price=preIco_price;
            limit=preIco_tokensLimit-preIco_sold;
            if (limit<0) limit=0;
            if (limit>totalSupply) limit=totalSupply;
        }
        if (now >= Ico_start && now <= Ico_end) {
            // ico stage
            current_price=Ico_price;
            limit=totalSupply;
        }

        if (current_price>0) {
            amount=msg.value/current_price;
            // check limit
            if (amount>limit) res_amount=limit; else res_amount=amount;
        }

        if ((current_price<=0) || (msg.value<current_price) || res_amount<=0) {
            /// retun funds
            require(this.balance>=msg.value);
    		if (msg.sender.send(msg.value)) {
    			Transfer(this,msg.sender, msg.value);
    		}
        } else  {
            // buy
            totalSupply -= res_amount;
            if (now >= preIco_start && now <= preIco_end) preIco_sold +=res_amount;
            if (now >= Ico_start && now <= Ico_end) Ico_sold +=res_amount;
            balanceOf[msg.sender] += res_amount;
            Transfer(this, msg.sender, res_amount);
            if (res_amount<amount) {
                /// cashback
                uint256 cashback=(amount-res_amount)*current_price;
                require(this.balance>=cashback);
        		if (msg.sender.send(cashback)) {
        			Transfer(this,msg.sender, cashback);
        		}
            }
        }
    }

	function safeWithdrawal(uint amount) onlyOwner {
		require(this.balance >= amount);
		// lock withdraw if stage not closed
		if ((now > preIco_end && now < Ico_start) || (now>Ico_end)) {
    		if (Owner.send(amount)) {
    			Transfer(this,msg.sender, amount);
    		}
		}
	}

}