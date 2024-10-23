import { createAppKit } from '@reown/appkit'
import { EthersAdapter } from '@reown/appkit-adapter-ethers'
import { mainnet, arbitrum } from '@reown/appkit/networks'
import { EventsController} from '@reown/appkit-core';

// 1. Get projectId from https://cloud.reown.com
const projectId = 'a7700938f2ed4f685a3bb5c578224139'

// 2. Create your application's metadata object
const metadata = {
  name: 'AppKit',
  description: 'AppKit Example',
  url: 'https://reown.com/appkit', // origin must match your domain & subdomain
  icons: ['https://avatars.githubusercontent.com/u/179229932']
} 

// 3. Create a AppKit instance
const modal = createAppKit({
  adapters: [new EthersAdapter()],
  networks: [mainnet, arbitrum],
  metadata,
  projectId, 
}) 

// 4. Connect to the wallet
const connectButton = document.getElementById("connectButton");
connectButton.addEventListener("click", async () => {  
    //Open the modal
    await modal.open() 
    //Get the connected wallet's address
    const account =  await modal.getAddress() 
    if (account!='undefined') {
        displayAccountInfo(account)
    }
}); 
 
// 5. Display the connected wallet's address
function displayAccountInfo(account) {
    if  (account&&account!='undefined') {
        document.getElementById("walletAddress").innerText = `Connected account: ${account}`;
    }
} 
 
// 6.  Subscribe handler
async function handler(newState) { 
    if (newState.data.event === 'CONNECT_SUCCESS') { 
        const account =  await modal.getAddress() 
        displayAccountInfo(account)
    }
 }
  
 // 7. Subscribe to events
 EventsController.subscribe(handler)
