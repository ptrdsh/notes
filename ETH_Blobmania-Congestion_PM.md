# Post Mortem on a Block Propagation Issue on Ethereum following Blobmania

This post mortem analyzes a block propagation issue on Ethereum that caused 13% of slots to be missed over a short period. The aim is to learn from this incident for the betterment of our ecosystem, especially as we approach multiple implementations of nodes and diverse indexers. Disclaimer: Simplifications for understandability were made. 

## EIP-4844 and Degens

Ethereum's Dencun Upgrade introduced "proto-danksharding" through EIP-4844. Proto-danksharding essentially abuses a free-text field for special purposes. 
Specifically, Dencun enabled free text in the call data field, which is tx data that is pruned out of the history after some time (aka making it temporarily onchain). Its intended purpose was to enable L2s to include some of their zk data in that field as its ok to have that pruned out after a period x, which in theory should have resulted in 50-500x cheaper L2 fees, than during pre-Dencun times... And thats also what happened and everyone was happy.
At least for about a week or two.
Users being degens, the first application besides the intended one was "cheap NFTs" through smth called "ethscriptions", developed by Facet, where the blob data field contains magic-prefixed and base64-encoded pics (yes. literal pics "on chain") that can be indexed directly out of the free text field and thus displayed/used for some stuff such as NFT markets.
Now while thats plenty stupid in itself (albeit technically mildly interesting), it caused a very interesting networking bug to occur. 

## MEV mempool Distribution and Overoptimizations

The bug occured in the interplay between one of the MEV mempool distribution networks by bloXroute (the BDN - blockchain distribution network, which is an alternative PAID mempool routing service/network, somewhat comparable to Mithril, but optimized for MEV, available for different chains) and a common lightnode implementation that is heavily used by block producers using the BDN. The BDN relays block data p2p through gossiping, but left out blob data for speed reasons (less data = faster propagation = faster inclusion onchain = better MEV extraction = more money for BDN block producers and MEV tx customers). They could just leave out the blob data, because so far, blob data contained mostly uninteresting L2 zk data, which didnt help their cause for MEV.

Due to these cheap ethscription NFTs and a resulting degen storm into them, the demand for blob space was so high, that every single block would have contained the max amount of blob data. But since the BDN didnt relay blob data p2p and (Lighthouse) block producers would only accept blocks p2p, the Lighthouse block producers couldnt fetch the required blob data, resulting in “timeouts” and “data not available” or "duplicate" error messages for when they would have been chosen to propose a block. Without that massive spike in demand, that compatibility issue wouldnt have mattered, because any non-Lighthouse-BDN block producer would have picked up the duty.

The result was that 13% of the network was rendered unable to produce blocks/ miss their slots, which caused a 13% drop in average block time.

## Learnings and Recommendations
(best through the words of the DBN and Lighthouse team)
_The BDN team is defining new criteria for testing and feature validation prior to release which will involve: increasing utilization of tools like kurtosis, improved usage of testnets, and closer collaboration with client teams. The Lighthouse team is also working to make Lighthouse compatible with the BDN’s prior behavior, in order to improve resilience. The assumption about whole block publishing proved to be too strong in the presence of relay optimizations._


## References:
- [Dencun/EIP-4844](https://eips.ethereum.org/EIPS/eip-4844)
- [ethscriptions](https://docs.ethscriptions.com/) & [Facet](https://docs.facet.org/)
- [BloXRoute](https://docs.bloxroute.com/introduction/why-use-bloxroute)
- [Research on blobs and associated fees](https://www.blocknative.com/blog/blobsplaining-part-2-lessons-from-the-first-eip-4844-congestion-event)
- [Official Post Mortem](https://gist.github.com/benhenryhunter/7b7d9c9e3218aad52f75e3647b83a6cc)
- [Block Count Chart](https://charts.coinmetrics.io/crypto-data/?id=8505)
