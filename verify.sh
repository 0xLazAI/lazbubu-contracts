source $1

if [[ -z "$CONTRACT_ADDRESS" || -z "$CONTRACT_NAME" || -z "$RPC_URL" || -z "$VERIFIER_URL" ]]; then
  echo "Usage: $0 <.env file>"
  echo "Required environment variables: CONTRACT_ADDRESS, CONTRACT_NAME, RPC_URL, VERIFIER_URL"
  echo "Example values: CONTRACT_ADDRESS=0xA2748Da4F9e53582557A0256d9feD34A8C0d4B28, CONTRACT_NAME=src/dat/Lazbubu.sol:Lazbubu, RPC_URL=https://testnet.lazai.network, VERIFIER_URL=https://testnet-explorer-api.lazai.network/api/"
  exit 1
fi

forge verify-contract \
  --rpc-url $RPC_URL \
  --verifier blockscout \
  --verifier-url $VERIFIER_URL \
  $CONTRACT_ADDRESS $CONTRACT_NAME