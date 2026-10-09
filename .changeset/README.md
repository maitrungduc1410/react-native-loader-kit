# Changesets

Every pull request that changes published behaviour adds a changeset:

```sh
yarn changeset
```

Pick the bump (patch for fixes, minor for new features, major for breaking changes) and write
one or two sentences for the changelog. The release workflow turns pending changesets into a
"chore: release vX.Y.Z" pull request (branch `release/vX.Y.Z`); merging that pull request
publishes to npm.

Always go through `yarn changeset`: the bare `changeset` / `npx changeset` command does not see
the library package because of the `example` workspace (see `scripts/changeset.mjs`).

The CLI needs Node.js 22.11 or newer (see `.nvmrc`). You can also write the file by hand: any
`.changeset/<name>.md` with this content works the same way.

```md
---
'react-native-loader-kit': patch
---

Fix the indicator not restarting after the app returns to the foreground.
```
