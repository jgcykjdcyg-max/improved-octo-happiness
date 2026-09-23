# improved-octo-happiness

## Requires Git LFS

Large files in this repo (`*.zip`, `*.mp4`, `*.part-*` — see `.gitattributes`) are stored with
[Git LFS](https://git-lfs.com). Without it, a clone or pull checks out small text **pointer files**
instead of the real content, and the zips fail to open with "unsupported format".

Install it once per machine, then fetch the real files:

```bash
brew install git-lfs   # or download from https://git-lfs.com
git lfs install        # one-time per user account
git lfs pull           # run inside the repo; downloads ~5 GB
```

Check that it worked — this should print `Zip archive data`, not `ASCII text`:

```bash
file "ios internals/"*.zip
```

Then rebuild the split video (it is over the 2 GB LFS per-file limit) and verify its checksum:

```bash
"ios internals/reassemble.sh"
```

> GitHub's **Code → Download ZIP** button does not include LFS content — clone the repo instead.
