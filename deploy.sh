source $1
ln -sf $1 .env
forge script script/Deploy.s.sol:Deploy --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --slow
rm -f .env