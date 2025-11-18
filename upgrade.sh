source $1
rm -rf out/
forge script script/UpgradeLazbubu.s.sol:UpgradeLazbubu --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --slow

