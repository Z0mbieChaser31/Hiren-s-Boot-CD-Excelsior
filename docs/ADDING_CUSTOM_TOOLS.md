# Adding Custom Tools to Hiren's Boot CD Excelsior

How to add your own ISOs, update existing entries, or contribute new tools to the official catalog.

---

## Option 1: Just Drop an ISO on the USB Drive (Easiest)

No configuration needed at all:

1. Copy any `.iso`, `.img`, `.wim`, or `.vhd` file into the `ISOs/` folder on your USB drive
2. Organize into subfolders for a cleaner menu (e.g., `ISOs/Custom/mytool.iso`)
3. Ventoy automatically detects and lists it in the boot menu on next boot

That's it. Ventoy supports virtually all bootable image formats.

---

## Option 2: Add to the Catalog (for `setup.py` auto-download)

To make your tool downloadable by the setup script, add it to `iso_catalog.json`.

### Step 1 — Add an ISO entry

Open `iso_catalog.json` and add a new key under `"isos"`:

```json
{
  "isos": {
    "your-tool-key": {
      "name": "Your Tool Name",
      "category": "Linux",
      "description": "What this tool does and when you'd use it. Be specific.",
      "homepage": "https://yourtool.example.com/",
      "download_page": "https://yourtool.example.com/download",
      "mirror": "https://direct.example.com/yourtool-latest.iso",
      "filename": "yourtool-latest.iso",
      "size_mb": 500,
      "uefi": true,
      "legacy_bios": true,
      "architecture": "x86_64",
      "requires_license": false,
      "notes": "Any caveats or usage notes.",
      "sha256": "optional-sha256-checksum-for-verification"
    }
  }
}
```

**Field reference:**

| Field | Required | Description |
|-------|----------|-------------|
| `name` | ✅ | Human-readable tool name |
| `category` | ✅ | `Windows`, `Linux`, `Diagnostics`, `Security`, `Network`, or `Other` |
| `description` | ✅ | What it does and when to use it |
| `homepage` | ✅ | Official project website URL |
| `download_page` | ✅ | Page where users can manually download |
| `mirror` | ⚠️ | **Direct** download URL (required for auto-download) |
| `filename` | ✅ | Filename to save the ISO as on the USB drive |
| `size_mb` | ✅ | Approximate download size in MB |
| `uefi` | ✅ | `true` if the ISO supports UEFI boot |
| `legacy_bios` | ✅ | `true` if the ISO supports Legacy BIOS boot |
| `architecture` | ✅ | `x86_64`, `x86`, `arm64`, etc. |
| `requires_license` | ✅ | `true` for paid/licensed tools |
| `sha256` | ❌ | Optional SHA-256 hash — enables automatic verification after download |
| `notes` | ❌ | Additional info shown to users before download |

### Step 2 — Add to a profile (optional)

To include the tool in a download profile, add its key to the profile's `isos` list:

```json
{
  "profiles": {
    "standard": {
      "description": "Well-rounded toolkit",
      "isos": ["hirens-pe", "systemrescue", "your-tool-key"]
    },
    "my-custom-profile": {
      "description": "My personal toolkit",
      "isos": ["hirens-pe", "your-tool-key"]
    }
  }
}
```

### Step 3 — Add a friendly boot menu alias (optional)

For a nice display name in the Ventoy boot menu, add to `ventoy/ventoy.json`:

```json
{
  "menu_alias": [
    {
      "image": "/ISOs/Linux/yourtool-latest.iso",
      "alias": "🔧  Your Tool Name  —  Brief description here"
    }
  ]
}
```

Then copy the updated `ventoy/ventoy.json` to your USB drive's `/ventoy/` folder.

---

## Testing Your Addition

```bash
# Check that your entry appears in the ISO list
python setup.py --list-isos

# Validate that the download URL is reachable (no actual download)
python setup.py --dry-run

# Download just your tool to a test folder
python setup.py --isos-only --dest ./test-isos --profile my-custom-profile
```

After downloading, boot it in a virtual machine (VirtualBox, QEMU, VMware) to confirm it works.

---

## Contributing to the Official Catalog

If your tool should be listed for everyone:

1. **Fork** the repository on GitHub
2. **Add** your ISO entry to `iso_catalog.json`
3. **Update** `docs/TOOLS_GUIDE.md` with a brief description and use-case note
4. **Test** that:
   - The `mirror` URL downloads correctly
   - The SHA-256 checksum matches (if provided)
   - The ISO boots in Ventoy (test in a VM)
5. **Submit a Pull Request** with:
   - The `iso_catalog.json` change
   - A brief explanation of what scenarios this tool solves
   - Confirmation it boots under Ventoy in both UEFI and Legacy BIOS if applicable

### Contribution standards

| Requirement | Detail |
|-------------|--------|
| **Actively maintained** | Updated within the last 2 years |
| **Reputable source** | Official project website or well-known mirror |
| **Free preferred** | Paid tools allowed but must be marked `requires_license: true` |
| **Direct URL** | The `mirror` field must be a stable direct download link, not a form or redirect |
| **No malware** | Must be verifiably safe — checksum strongly encouraged |
| **Boots under Ventoy** | Must have been confirmed to boot; note any special Ventoy plugin needed |

---

## Updating an Existing ISO

When an ISO you use gets a new version:

1. Update the `mirror` URL to the new download link
2. Update `sha256` if available (get it from the project's checksums page)
3. Update `size_mb` if the size changed significantly
4. Submit a Pull Request or open an issue with the update

For broken/dead download links, open a GitHub issue — these get fixed quickly.

---

## Ventoy Plugin Notes

Some ISOs require a special Ventoy plugin to boot correctly. Check https://www.ventoy.net/en/plugin_entry.html for the list. If your ISO needs one, note it in the `notes` field:

```json
{
  "notes": "Requires Ventoy persistence plugin. See ventoy.net/en/plugin_persistence.html"
}
```
