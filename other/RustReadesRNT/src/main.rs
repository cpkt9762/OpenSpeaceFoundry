use abi::AbiEncode;
use ethers::prelude::*;
use ethers::providers::{Http, Provider};
use ethers::types::{H256, U256};
use ethers::utils::keccak256;
use std::convert::TryFrom;
use std::sync::Arc;
fn u256_to_h256(value: U256) -> H256 {
    let mut bytes = [0u8; 32];
    value.to_big_endian(&mut bytes);
    H256::from(bytes)
}
async fn get_lock_info(
    client: &Provider<Http>,
    contract_address: Address,
    index: u64,
) -> Result<(Address, u64, U256), ProviderError> {
    // Step 1: Calculate the storage slot for the array base as U256
    let base_slot: H256 = H256::zero();
    let array_hash = ethers::utils::keccak256(&base_slot.0);
    let array_slot = U256::from(array_hash);

    // Step 2: Calculate the specific slots for `user`, `startTime`, and `amount`
    // Convert `array_slot` to U256 and add the offsets
    let user_starttime_slot = array_slot + U256::from(index * 2);
    let user_starttime_data: H256 = client
        .get_storage_at(contract_address, u256_to_h256(user_starttime_slot), None)
        .await?;

    // `user` is the first 20 bytes of `user_starttime_data`
    let user = Address::from_slice(&user_starttime_data[12..32]);

    // `startTime` is the next 8 bytes after `user`
    let start_time_bytes = &user_starttime_data[4..12];
    let start_time = u64::from_be_bytes(start_time_bytes.try_into().unwrap());

    // Step 3: Calculate and retrieve the `amount` slot
    let amount_slot = array_slot + U256::from(index * 2 + 1);
    let amount_data: H256 = client
        .get_storage_at(contract_address, u256_to_h256(amount_slot), None)
        .await?;

    let amount = U256::from_big_endian(amount_data.as_bytes());

    Ok((user, start_time, amount))
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    dotenv::from_path(".env")?;
    let provider = Provider::<Http>::try_from(&std::env::var("TESTNET_RPC_URL")?)?;
    let client = Arc::new(provider);

    let contract_address: Address = "0x67f2885A76e4e0aCD23835D6436246ceD8aD0b2b".parse()?;
    // Fetch lock info for each index in the _locks array
    for i in 0..11 {
        match get_lock_info(&client, contract_address, i).await {
            Ok((user, start_time, amount)) => {
                println!(
                    "locks[{}]: user: {:?}, startTime: {}, amount: {:?}",
                    i, user, start_time, amount
                );
            }
            Err(e) => {
                println!("Failed to fetch lock info for index {}: {:?}", i, e);
            }
        }
    }
    Ok(())
}
