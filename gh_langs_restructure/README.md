# restructures GitHub Linguist JSON output to something not stupid

Output looks something like this:
```json
[{"lang":"Zig","size":143110,"percentage":"75.86"},{"lang":"Nix","size":4445,"percentage":"2.36"},{"lang":"Go","size":16779,"percentage":"8.89"},{"lang":"TypeScript","size":3845,"percentage":"2.04"},{"lang":"Shell","size":1545,"percentage":"0.82"},{"lang":"CSS","size":6386,"percentage":"3.38"},{"lang":"HTML","size":1867,"percentage":"0.99"},{"lang":"JavaScript","size":10683,"percentage":"5.66"}]
```

If you want something cleaner, learn what `jq` is.

### Dependencies
- Bun

<sub>it's just some JSON, and I only use Bun to run the `github-linguist --json` command</sub> 
