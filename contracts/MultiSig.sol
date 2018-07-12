pragma solidity ^0.4.20;

interface AbstractMultiSig {

  /*
   * This function should return the onwer of this contract or whoever you
   * want to receive the Gyaan Tokens reward if it's coded correctly.
   */
  function owner() external constant returns(address);

  /*
   * This event should be dispatched whenever the contract receives
   * any contribution.
   */
  event ReceivedContribution(address indexed _contributor, uint _valueInWei);

  /*
   * When this contract is initially created, it's in the state
   * "Accepting contributions". No proposals can be sent, no withdraw
   * and no vote can be made while in this state. After this function
   * is called, the contract state changes to "Active" in which it will
   * not accept contributions anymore and will accept all other functions
   * (submit proposal, vote, withdraw)
   */
  function endContributionPeriod() external;

  /*
   * Sends a withdraw proposal to the contract. The beneficiary would
   * be "_beneficiary" and if approved, this address will be able to
   * withdraw "value" Ethers.
   *
   * This contract should be able to handle many proposals at once.
   */
  function submitProposal(uint _valueInWei) external;
  event ProposalSubmitted(address indexed _beneficiary, uint _valueInWei);

  /*
   * Returns a list of beneficiaries for the open proposals. Open
   * proposal is the one in which the majority of voters have not
   * voted yet.
   */
  function listOpenBeneficiariesProposals() external view returns (address[]);

  /*
   * Returns the value requested by the given beneficiary in his proposal.
   */
  function getBeneficiaryProposal(address _beneficiary) external view returns (uint);

  /*
   * List the addresses of the contributors, which are people that sent
   * Ether to this contract.
   */
  function listContributors() external view returns (address[]);

  /*
   * Returns the amount sent by the given contributor in Wei.
   */
  function getContributorAmount(address _contributor) external view returns (uint);

  /*
   * Approve the proposal for the given beneficiary
   */
  function approve(address _beneficiary) external;
  event ProposalApproved(address indexed _approver, address indexed _beneficiary, uint _valueInWei);

  /*
   * Reject the proposal of the given beneficiary
   */
  function reject(address _beneficiary) external;
  event ProposalRejected(address indexed _approver, address indexed _beneficiary, uint _valueInWei);

  /*
   * Withdraw the specified value in Wei from the wallet.
   * The beneficiary can withdraw any value less than or equal the value
   * he/she proposed. If he/she wants to withdraw more, a new proposal
   * should be sent.
   *
   */
  function withdraw(uint _valueInWei) external;
  event WithdrawPerformed(address indexed _beneficiary, uint _valueInWei);

  /*
   * Returns whether a given signer has voted in the given proposal and if so,
   * what was his/her vote.
   *
   * @returns 0: if signer has not voted yet in this proposal, 1: if signer
   * has voted YES in this proposal, 2: if signer has voted NO in this proposal
   */
  function getSignerVote(address _signer, address _beneficiary) view external returns(uint);

}

contract MultiSig is AbstractMultiSig {

  address public owner = msg.sender;
  address public signer1;
  address public signer2;
  address public signer3;
  enum contractState {Accepting_contributions,Active}
  enum openProposalState {Open,Closed}
  enum voteStatus {NA,Yea,Nay}
  contractState state;
  
  
   struct openproposaldata {
     uint value;
     openProposalState proposalState;
     mapping(address => voteStatus) votes;
     mapping(address => address) voters;
     uint yea_count;
     uint nay_count;
     uint na_count;
     bool isExists;
     address beneficiary;
     uint index;
   }
   struct contributorsdata{
       uint value;
   }
   struct signersdata{
       bool exists;
   }
  
  mapping (address => signersdata) public members;
  mapping(address => openproposaldata) public openProposals;
  mapping(address => contributorsdata) public contributors;
  address[] public openProposalAddresses;
  address[] public contributorAddresses;
  event test_value(uint indexed percentamt);
  modifier onlyMembers() {
        require(msg.sender == owner || members[msg.sender].exists == true);
        _;
    }
  
  function MultiSig(){
    state = contractState.Accepting_contributions;
    signer1 = 0xfa3c6a1d480a14c546f12cdbb6d1bacbf02a1610;
    signer2 = 0x2f47343208d8db38a64f49d7384ce70367fc98c0;
    signer3 = 0x7c0e7b2418141f492653c6bf9ced144c338ba740;
    members[signer1].exists = true;
    members[signer2].exists = true;
    members[signer3].exists = true;
   }
    
   function owner() external constant  returns(address){
       return owner;
   }
   
   function endContributionPeriod() onlyMembers external{
       state = contractState.Active;
   }
   
   function startContributionPeriod() onlyMembers external{
       state = contractState.Accepting_contributions;
   }
  
   function remove_at_index(uint index) onlyMembers returns(address[]) {
        if (index >= openProposalAddresses.length) return;

        for (uint i = index; i<openProposalAddresses.length-1; i++){
            openProposalAddresses[i] = openProposalAddresses[i+1];
        }
        delete openProposalAddresses[openProposalAddresses.length-1];
        openProposalAddresses.length--;
        return openProposalAddresses;
    }
  
   function contract_balance() external view returns (uint){
       return this.balance;
   }
  
   function submitProposal(uint _valueInWei)  external {
       
       require(state == contractState.Active);
      uint prevProposalValue = openProposals[msg.sender].value;
       uint expectedProposalValue = prevProposalValue + _valueInWei;
       uint current_contract_balance = this.balance;
        uint amtPercentage =  (expectedProposalValue * 100)  / current_contract_balance;
        if(amtPercentage <= 10){
       
         test_value(amtPercentage);
       openProposals[msg.sender].value += _valueInWei;
       openProposals[msg.sender].proposalState = openProposalState.Open;
       openProposals[msg.sender].votes[signer1] = voteStatus.NA;
       openProposals[msg.sender].votes[signer2] = voteStatus.NA;
       openProposals[msg.sender].votes[signer3] = voteStatus.NA;
       openProposals[msg.sender].yea_count = 0;
       openProposals[msg.sender].nay_count = 0;
       openProposals[msg.sender].na_count = 3;
       // if the proposal index not exists then create a new one
       if( !openProposals[msg.sender].isExists){
          openProposals[msg.sender].isExists = true;
          openProposals[msg.sender].index = openProposalAddresses.length-1;
          openProposalAddresses.push( msg.sender);
       } 
       
       openProposals[msg.sender].beneficiary = msg.sender;
       
       ProposalSubmitted(msg.sender, openProposals[msg.sender].value);
     
    }else revert('Error trying to propose more than 10%');
       
   }
   
   function listOpenBeneficiariesProposals() external view returns (address[]){
       return openProposalAddresses;
   }
   
   function getBeneficiaryProposal(address _beneficiary) external view returns (uint){
       return openProposals[_beneficiary].value;
   }
   
    function listContributors() external view returns (address[]){
        return contributorAddresses;
    }
    
    function getContributorAmount(address _contributor) external view returns (uint){
        return contributors[_contributor].value;
    }
    
   
    
    function approve(address _beneficiary) onlyMembers external{
        require(openProposals[_beneficiary].isExists);
        require(openProposals[_beneficiary].proposalState == openProposalState.Open);
        // check if this signer has voted already, then we dont need to do anything
        require(openProposals[_beneficiary].votes[msg.sender] != voteStatus.Yea);
        
      /*  if(openProposals[_beneficiary].votes[msg.sender] == voteStatus.Nay){
            openProposals[_beneficiary].votes[msg.sender] = voteStatus.Yea;
             openProposals[_beneficiary].yea_count += 1;
             openProposals[_beneficiary].nay_count -= 1;
        } */
        if(openProposals[_beneficiary].votes[msg.sender] == voteStatus.NA){
            openProposals[_beneficiary].votes[msg.sender] = voteStatus.Yea;
             openProposals[_beneficiary].yea_count += 1;
             openProposals[_beneficiary].na_count -= 1;
        }
        
         ProposalApproved(msg.sender, _beneficiary,openProposals[_beneficiary].value );
         // check to ee if the treshold yea votes received to transfer the funds
        if( openProposals[_beneficiary].yea_count >= 2){
            // proposal approved, now transfer the funds to the benficiary
            openProposals[_beneficiary].proposalState = openProposalState.Closed;
            openProposalAddresses = remove_at_index(openProposals[_beneficiary].index);
        }
       
    }
    
    function reject(address _beneficiary) onlyMembers external{
        require(openProposals[_beneficiary].isExists);
        require(openProposals[_beneficiary].proposalState == openProposalState.Open);
        // check if this signer has voted already, then we dont need to do anything
        require(openProposals[_beneficiary].votes[msg.sender] != voteStatus.Nay);
        
      /*  if(openProposals[_beneficiary].votes[msg.sender] == voteStatus.Yea){
            openProposals[_beneficiary].votes[msg.sender] = voteStatus.Nay;
             openProposals[_beneficiary].nay_count += 1;
             openProposals[_beneficiary].yea_count -= 1;
        } */
        if(openProposals[_beneficiary].votes[msg.sender] == voteStatus.NA){
            openProposals[_beneficiary].votes[msg.sender] = voteStatus.Nay;
             openProposals[_beneficiary].nay_count += 1;
             openProposals[_beneficiary].na_count -= 1;
        }
        
         ProposalRejected(msg.sender, _beneficiary,openProposals[_beneficiary].value );
         // check to ee if the treshold yea votes received to transfer the funds
        if( openProposals[_beneficiary].nay_count >= 2){
            // proposal approved, now transfer the funds to the benficiary
            openProposals[_beneficiary].proposalState = openProposalState.Closed;
             openProposalAddresses = remove_at_index(openProposals[_beneficiary].index);
            
        }
    }
    
    function withdraw(uint _valueInWei) external{
        // check if the contract is in Active state where proposals can be submitted, approved and amt can be withdrawn
        // check if the sender exists in beneficiary list
        //check if their proposal has max yea'sender
        // check if the value they want to withdraw greater than 0
        require(state == contractState.Active);
        require(openProposals[msg.sender].isExists);
        require(openProposals[msg.sender].yea_count >= 2); 
        require(_valueInWei > 0 && _valueInWei <= openProposals[msg.sender].value);
        // after all checks have passed, then transfer the amount and deduct the balance from user value
        openProposals[msg.sender].value -= _valueInWei;
        openProposals[msg.sender].beneficiary.transfer(_valueInWei);
            
        
    }

    function getValue() returns (uint) {
        return (30);
    }

function openProposalADD() view external returns(address[]) {
    return openProposalAddresses;
}
    
function getSignerVote(address _signer, address _beneficiary) view external returns(uint) {
        if(openProposals[_beneficiary].votes[_signer] == voteStatus.NA) return (0);
        if(openProposals[_beneficiary].votes[_signer] == voteStatus.Yea) return (1);
        if(openProposals[_beneficiary].votes[_signer] == voteStatus.Nay) return (2);
    }
   
   function () payable{
       // fallback function to accept contributions
       require(msg.value != 0);
       require(state == contractState.Accepting_contributions);
       contributors[msg.sender].value += msg.value;
       contributorAddresses.push(msg.sender);
       ReceivedContribution(msg.sender,msg.value);
   }
 }
