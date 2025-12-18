source $1
ln -sf $1 .env
rm -rf out/
forge script script/UpgradeLazbubu.s.sol:UpgradeLazbubu --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --slow
rm -f .env
