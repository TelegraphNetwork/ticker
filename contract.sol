pragma solidity ^0.4.13;

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

contract Feed is Owned {
    uint public basePrice = 0.005 ether;
    uint public k = 1;
    uint public showInterval = 15;
    uint public totalMessages = 0;

    struct Message {
        string content;
        uint show_date;
    }

    mapping (uint => Message) public messageInfo;

    /* Events */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Init contract  */
    function Feed() {

    }

    /* Fallback function */
    function() public payable {
        throw;
    }

    /* Calc messages count in queue */
    function queueCount() constant internal returns (uint _count) {
        for (uint i = totalMessages; i > 0; i --) {
            if (messageInfo[i].show_date < (now - showInterval)) return _count;
            _count ++;
        }
        return _count;
    }

    /* Sync time */
    function currentTime() constant public returns (uint _now) {
        return now;
    }

    /* Get message by timestamp */
    function currentMessage(uint _now) constant public returns ( uint _message_id, string _content, uint _show_date, uint _show_interval, uint _serverTime) {
        require(totalMessages > 0);
        if (_now == 0) _now = now;
        for (uint i = totalMessages; i > 0; i --) {
            if (messageInfo[i].show_date >= (_now - showInterval) && messageInfo[i].show_date < _now) {
                if (messageInfo[i+1].show_date > 0) _show_interval = messageInfo[i + 1].show_date - messageInfo[i].show_date; else _show_interval = showInterval;
                return (i, messageInfo[i].content, messageInfo[i].show_date, _show_interval, _now);
            }
            if (messageInfo[i].show_date < (_now - showInterval)) throw;
        }
        throw;
    }

    /* Submit message to queue */
    function submitMessage(string _content) payable public returns(uint _message_id, uint _message_price, uint _queueCount) {
        require(msg.value > 0);
        if (bytes(_content).length < 1 || bytes(_content).length > 150) throw;
        uint total = queueCount();
        uint _last_Show_data = messageInfo[totalMessages].show_date;
        if (_last_Show_data == 0) _last_Show_data = now + showInterval*2; else {
            if (_last_Show_data < (now - showInterval)) {
                _last_Show_data = _last_Show_data + (((now - _last_Show_data) / showInterval) + 1) * showInterval;
            } else _last_Show_data = _last_Show_data + showInterval;
        }
        uint message_price = basePrice + basePrice * total * k;
        require(msg.value >= message_price);

        totalMessages ++;
        messageInfo[totalMessages].content = _content;
        messageInfo[totalMessages].show_date = _last_Show_data;

        if (msg.value > message_price) {
            uint cashback = msg.value - message_price;
            sendMoney(msg.sender, cashback);
        }

        return (totalMessages, message_price, (total + 1));
    }

    /* Get message price and count */
    function queueInfo() constant public returns( uint _message_price, uint _queueCount) {
        uint total = queueCount();
        uint message_price = basePrice + basePrice * total * k;
        return (message_price, total);
    }

    /* Send money to recepient */
	function sendMoney(address _address, uint _amount) internal {
		require(this.balance >= _amount);
    	if (_address.send(_amount)) {
    		Transfer(this, _address, _amount);
    	}
	}

	/* Withdraw function */
	function withdrawBenefit(address _address, uint _amount) onlyOwner public {
		sendMoney(_address, _amount);
	}

    /* Set basePrice parameter */
	function setBasePrice(uint _newprice) onlyOwner public {
		require(_newprice > 0);
		basePrice = _newprice;
	}

	/* Set showInterval parameter */
	function setShowInterval(uint _newinterval) onlyOwner public {
		require(_newinterval > 0);
		showInterval = _newinterval;
	}

	/* Set k parameter */
	function setPriceMultiplier(uint _new_k) onlyOwner public {
		require(_new_k > 0);
		k = _new_k;
	}

}