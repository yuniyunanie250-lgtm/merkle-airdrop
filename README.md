# merkle-airdrop

A merkle-root airdrop distributor in ~55 lines of Solidity. Claim once, prove
membership, no on-chain list of recipients.

The point of a merkle airdrop is cost: an airdrop to 50,000 addresses stored in a
mapping costs roughly 50,000 storage writes to deploy. Storing one 32-byte root
costs one, and each recipient pays for their own proof.

## Leaf format

```
keccak256(abi.encodePacked(uint256 index, address account, uint256 amount))
```

This matches the Javascript generators in OpenZeppelin's merkle-tree library, so
existing tooling produces compatible proofs.

## Hashing rule

Pairs are sorted before hashing (`a <= b ? hash(a,b) : hash(b,a)`). Without
sorting, a proof is only valid for the exact order the tree was built in, and
verification silently fails for half the leaves.

## What it deliberately does not do

- **No admin.** The root is immutable and there is no sweep. If you need to
  recover unclaimed funds after a deadline, add an owner and an expiry — and note
  that this makes the distributor upgradeable in effect.
- **No token support.** Native value only.
- **No per-account cap.** Each leaf is one claim; sending the same account two
  leaves is allowed by construction.

## Development

```bash
forge install foundry-rs/forge-std
forge test -vvv
```

## License

MIT
