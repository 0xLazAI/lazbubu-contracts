source $1
ln -sf $1 .env
forge script script/DeploySimple.s.sol:DeploySimple --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --slow
rm -f .env