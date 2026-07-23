# How to Contribute to Hiren's Boot CD Excelsior

Thank you for helping keep this project alive! 🙌

---

## Ways to Contribute

- 🐛 **Report bugs** — Something broken? [Open an issue](https://github.com/HBCD/Hiren-s-Boot-CD-reborn/issues)
- 🔧 **Add a tool** — Know a great open-source rescue tool? Add it to the manifest
- 📖 **Improve docs** — Clearer guides, translated docs, examples
- 🖥 **Test hardware** — Boot on real machines and report compatibility
- 🎨 **Improve the boot theme** — Make the GRUB menu look better
- 🔁 **Update tool versions** — Keep the manifest current

---

## Ground Rules

1. **Only open-source tools** — All tools must be free and open-source with a compatible license
2. **No Windows-only tools** — Must work in the Linux rescue environment
3. **No binary blobs in Git** — Scripts, configs, and manifests only
4. **Test your changes** — Build the ISO and verify it boots before opening a PR

---

## Adding a New Tool

### Quick Method (via script)

```bash
bash excelsior/scripts/add-tool.sh --interactive
```

Follow the prompts to add the tool to `excelsior/tools/MANIFEST.json`.

### Manual Method

Edit `excelsior/tools/MANIFEST.json` and add an entry to the `tools` array:

```json
{
  "name": "mytool",
  "version": "1.2.3",
  "category": "disk",
  "description": "Brief description of what it does",
  "url": "https://mytool.example.com",
  "license": "GPL-2.0",
  "package": "mytool",
  "replaces": "OldTool from HBCD (if applicable)"
}
```

**Valid categories**: `disk`, `recovery`, `security`, `system`, `network`, `utility`

### If the tool needs a new boot menu entry

Edit `excelsior/boot/grub/grub.cfg` and add a `menuentry` block following the existing pattern.

---

## Updating Tool Versions

1. Find the tool in `excelsior/tools/MANIFEST.json`
2. Update `"version"` and `"url"` fields
3. If the tool has a new download URL for the build script, update it in `excelsior/scripts/build.sh`

---

## Improving the Build Script

The build script is `excelsior/scripts/build.sh`. Key areas:

- **`SYSRESCUE_VERSION` / `GPARTED_VERSION` / `MEMTEST_VERSION`** — Version pins at the top
- **`extract_sysrescue()`** — Handles SystemRescue ISO unpacking
- **`create_hybrid_iso()`** — The `xorriso` command that creates the final ISO

Run `shellcheck excelsior/scripts/build.sh` before submitting.

---

## Submitting a Pull Request

1. Fork the repo
2. Create a branch: `git checkout -b feat/add-mytool`
3. Make your changes
4. Validate configs:
   ```bash
   grub-script-check excelsior/boot/grub/grub.cfg
   jq empty excelsior/tools/MANIFEST.json
   shellcheck excelsior/scripts/*.sh
   ```
5. Commit with a descriptive message: `Add foobar tool to disk category`
6. Push and open a PR against `Hiren-s-Boot-CD-Excelsior`

---

## Code Style

- **Bash scripts**: 2-space indentation, `set -euo pipefail`, shellcheck-clean
- **JSON files**: Formatted with 2-space indentation
- **Markdown**: Standard GitHub-flavored markdown
- **GRUB config**: Comment each menu entry with its purpose

---

## Testing Checklist (Before PR)

- [ ] `grub-script-check excelsior/boot/grub/grub.cfg` passes
- [ ] `jq empty excelsior/tools/MANIFEST.json` passes
- [ ] `shellcheck excelsior/scripts/*.sh` passes
- [ ] ISO builds without errors: `sudo bash excelsior/scripts/build.sh`
- [ ] ISO boots in QEMU: `bash excelsior/scripts/verify-iso.sh Excelsior.iso --uefi`
