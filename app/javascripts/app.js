import "../stylesheets/app.css";
import { default as Web3} from 'web3';
import { default as contract } from 'truffle-contract'

import registryArtifacts from '../../build/contracts/MultiSig.json'
var MultiSig = contract(registryArtifacts);

var account;

window.App = {
  start: function() {
    var self = this;
    MultiSig.setProvider(window.web3.currentProvider);

    window.web3.eth.getAccounts(function(err, accounts) {
      if(err){
        console.log('Error fetching accounts from web3 provider - ', err)
      }
      console.log('Identified Accounts from your web3 provider - ', accounts)
      if (typeof accounts[0] == 'undefined') {
        alert("MetaMask is locked. Unlock it by entering your password and refresh this page");
        return;
      }
      account = accounts[0];

     App.contractBalance();

      // listen to logs 
      App.listentToAllEvents();
    });
  },

  listentToAllEvents: function(){
    var self = this;
    //MultiSig.setProvider(window.web3.currentProvider);
    MultiSig.deployed().then(function(instance){
      console.log(instance);
    //  console.log(instance.contract.events.allEvents());
      instance.contract.allEvents((err, result) => {
        if(err){
          console.log('Error when listening to events - ',err)
        }
        if(result){
          console.log('Got an Event data ',result)
          var a = document.getElementById("tat");
          var row = a.insertRow(0);
          var cell1 = row.insertCell(0);
          cell1.innerHTML = JSON.stringify(result);

        }
       
      });
    }).catch(function(e){
      console.log(e);
    })
  },

  
  getV: function(){
    var self = this;
    //MultiSig.setProvider(window.web3.currentProvider);
    MultiSig.deployed().then(function(instance){
      return instance.getValue();
    }).then(function(result){
      var a = document.getElementById("g");
      a.innerHTML = result.logs;
      console.log(result);
    }).catch(function(e){
      console.log(e);
    })
  },

  // Show the Contract Balance
  contractBalance: function(){var self = this;
  MultiSig.deployed().then(function(instance){
    return instance.contract_balance();
  }).then(function(result){
    console.log( web3.fromWei(result.toNumber(), "ether" ) )
    console.log(MultiSig.address);
   document.getElementById("balanceC").value = web3.fromWei(result.toNumber(), "ether" ) 
  }).catch(function(e){
    console.log(e);
  })
  },

// Contribute to the Contract -- Not implemented
// How do I do this?
submitCont: function() {
  var self = this;
  var val = document.getElementById("subCont").value;
  MultiSig.deployed().then(function(instance){
    return instance.contract.contract_balance(
      {from: account,
  to:MultiSig.address,
  value: Number(val),
  gas: 300000},(err,result) =>{
    if(err){
      console.log('Error sending ether to multisig - ', err)
    }if(result){
      web3.eth.sendTransaction({
        from: account,
        to:MultiSig.address,
        value: Number(val),
        gas: 300000,
       }, (err,data) => {
          if(err){
            console.log('Error sending ether to multisig - ', err)
          }if(data){
            console.log('Sent Ether to the Multisig contract succesful - ',data)
          }
       });
      console.log('Sent Ether to the Multisig contract succesful - ',result)
      console.log( web3.fromWei(result.toNumber(), "ether" ) )
    console.log(MultiSig.address);
   document.getElementById("balanceC").value = web3.fromWei(result.toNumber(), "ether" ) 
    }
  }
    );
  }).catch(function(e){
    console.log(e);
  })

},


// Show list of Contributors
contributorsList: function(){
  var self = this;
  document.getElementById("conList").innerHTML = "";
  MultiSig.deployed().then(function(instance){
    instance.contract.listContributors({from:account},((er,data)=>{
      var x = document.getElementById("conList");
      // result.tx = tx hash
        // result.receipt
        // result.logs
        console.log('Error while fetching the list of contributors - ',er)
        console.log('Fetched the list of contributors ',data);
       for (var i = 0; i < data.length; i++) {
          var option = document.createElement("option");
          option.text = data[i];
          x.add(option);
        }
    }));

  }).catch(function(e){
    console.log(e);
  })
},

//Show the amount contributed by an Individual (Address)
contributedAmt: function(){
 var self = this;

var addr = document.getElementById("conAdd").value;
 MultiSig.deployed().then(function(instance){
   console.log('Got the Multisig instance - ',instance)
   instance.contract.getContributorAmount(addr,{from:account} ,(er,data)=>{
    if(er){
      console.log('Err fetching the contributors amount ',er)
    }if(data){
      console.log('Got contributor amount - ',data)
      console.log('Fetched Contributor Amount from contract - ')
      document.getElementById("conValue").value = web3.fromWei(data.toNumber(), "ether" ) 
      //return data;
    }
  })
   
 }).catch(function(e){
   console.log(e);
 })
},

// End Contribution Period
endContribution: function(){
  var self = this;

  MultiSig.deployed().then(function(instance){
     instance.contract.endContributionPeriod({from:account},(er,data)=>{
       if(er){
         console.log('Error changing the status of contribution - ', er)
       }
       if(data){
         console.log('Success ending the contribution - ',data)
        
         document.getElementById("state").value = "Contribution Period Ended"
        
       }
     })
  }).catch(function(e){
    console.log(e);
  })
},

// Submit a Proposal
submitProp: function(){
  var self = this;

  MultiSig.deployed().then(function(instance){
    var val = document.getElementById("subProp");
    return instance.contract.submitProposal(Number(val), {from: account,
    to:MultiSig.address,
    value: Number(val),
    gas: 300000},(er,data)=>{
      if(er){
        console.log('Error when submitting the proposal',er)
      }
      if(data){
        console.log('Submit proposal tx ',data);
        alert("Proposal Submitted Successfully");
      } 
   
    });
  }).catch(function(e){
    console.log(e);
  })
},

// List of Open Beneficiaries
openPropList: function() {
  var self = this;

  MultiSig.deployed().then(function(instance){
    
    instance.contract.listOpenBeneficiariesProposals({from:account},((er,data)=>{
      var x = document.getElementById("benList");
      document.getElementById("benList").innerHTML = "";
      // result.tx = tx hash
        // result.receipt
        // result.logs
        console.log('Error while fetching the list of beneficiries - ',er)
        console.log('Fetched the list of open proposals ',data);
       for (var i = 0; i < data.length; i++) {
          var option = document.createElement("option");
          option.text = data[i];
          x.add(option);
        }
    }));
  }).catch(function(e){
    console.log(e);
  })
},

listProposals: function(){
  var self = this;
  //MultiSig.setProvider(window.web3.currentProvider);
  MultiSig.deployed().then(function(instance){
    instance.contract.openProposalADD((err, result) => {
      if(err){
        console.log('Error when listening the open proposal addreses - ',err)
      }
      if(result){
        console.log('Got Open Proposals',result)
        for (var i = 0; i < result.length; i++) {
          instance.contract.openProposals(result[i],{from: account,
            to:MultiSig.address,
            gas: 30000000},(error,openproposal)=>{
             if(error){
               console.log('Error when fetching the Open Proposal for address',error)
             }if(openproposal){
              console.log('Fetched the Open Proposal ',JSON.stringify(openproposal))
              var option = document.createElement("option");
          option.text = JSON.stringify(openproposal);
          voteVal.add(option);
             }
          })
          
        }
      }
     
    });
  }).catch(function(e){
    console.log(e);
  })
},

approve: function(){
  var self = this;

  MultiSig.deployed().then(function(instance){
    var val = document.getElementById("voteVal");
    return instance.contract.approve(val, {from:account},(er,data) => {
       if(er){
         console.log('Error approving the proposal ', er)
       }
       if(data){
        console.log('Success Approving the proposal', data)
       }
    });
  }).catch(function(e){
    console.log(e);
  })
},

reject: function(){
  var self = this;

  MultiSig.deployed().then(function(instance){
    var val = document.getElementById("voteVal");
    return instance.contract.reject(val, {from:account},(er,data) => {
       if(er){
         console.log('Error approving the proposal ', er)
       }
       if(data){
        console.log('Success Approving the proposal', data)
       }
    });
  }).catch(function(e){
    console.log(e);
  })
}
};
/*
  refreshGet: function() {
    var self = this;

    SimpleRegistry.deployed().then(function(instance) {
      return instance.get.call('test');
    }).then(function(value) {
      var getResult = document.getElementById("getResult");
      getResult.innerHTML = value.valueOf();
    }).catch(function(e) {
      console.log(e);
    });
  },

  /*setNewValue: function() {
    var self = this;

    var newValue = parseInt(document.getElementById("newValue").value);

    SimpleRegistry.deployed().then(function(instance) {
      return instance.register('test', newValue, {from: account});
    })
    .then(function(result) {
      // result.tx = tx hash
      // result.receipt
      // result.logs
      console.log(result);
      for (var i = 0; i < result.logs.length; i++) {
        var log = result.logs[i];
        if (log.event == "NewValueRegistered") {
          console.log('Found NewValueSet', result.logs[i]);
        }
      }
    }).catch(function(e) {
      console.log(e);
    });
  }
}; */


/* ######Template######## #/
endContribution: function(){
  var self = this;

  MultiSig.deployed().then(function(instance){
    return instance.gfgfg(,{});
  }).then(function(result){
    console.log(result);
  }).catch(function(e){
    console.log(e);
  })

}, */ 




window.addEventListener('load', function() {
  if (typeof web3 !== 'undefined') {
    window.web3 = new Web3(web3.currentProvider);
  
  } else {
    alert('MetaMask is not installed!');
  }
  App.start();
});
