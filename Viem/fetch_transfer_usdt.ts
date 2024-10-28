import { createPublicClient, http, parseAbiItem, formatUnits } from 'viem';
import { mainnet } from 'viem/chains';
import { ethers } from 'ethers';
// Create a public client connected to the Ethereum mainnet
const client = createPublicClient({
  chain: mainnet,
  transport: http('https://rpc.flashbots.net'),
});

// USDC contract address
const USDC_ADDRESS  = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';

// ABI for the Transfer event
const TRANSFER_EVENT_ABI = parseAbiItem(
  'event Transfer(address indexed from, address indexed to, uint256 value)'
);

async function fetchUsdcTransfers() { 
    try{
    // Get the latest block number 
    const latestBlock = await client.getBlockNumber();
    const startBlock = BigInt(latestBlock) - BigInt(100);

    // Use the getLogs method to fetch logs for the Transfer event of the USDC contract
    const filter = await client.createEventFilter({
      address: USDC_ADDRESS,
      event: TRANSFER_EVENT_ABI,
      fromBlock: startBlock,
      toBlock: 'latest',
    });

    const logs = await client.getFilterLogs({ filter });

    let i=0;
    // Process and display the logs for the Transfer event
    logs.forEach(log => {
      const { args, transactionHash } = log;
      // Access properties directly
      const from = args.from;
      const to = args.to;
      const value = args.value;
    
      if (value !== undefined) {
        // Convert the value from the smallest unit to USDC (6 decimal places)
        const usdcValue = ethers.formatUnits(value, 6);

        console.log(
          `(${i}) Transferred ${usdcValue} USDC from ${from} to ${to}, Transaction ID: ${transactionHash}`
        );
      } else {
        console.warn(`Value is undefined for transaction: ${transactionHash}`);
      }
      i++;
    });

    console.log('USDC transfer events fetched successfully.');
    } catch (error) {
    console.error('Error fetching USDC transfer events:', error);
    }
}

fetchUsdcTransfers().catch(console.error);

