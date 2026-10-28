# ShrubTwitch 1.2 — Build Fix / Codespaces setup

## 1. Upload and deploy in ONE command

1. Open **your ShrubTwitch fork** on GitHub → **Code → Codespaces → Create codespace on main** (or open your existing Codespace).
2. Drag/upload **ShrubTwitch-1.2-BuildFix.zip** to the **top-level/root** of your repository in the Codespaces Explorer. The ZIP should appear beside `Makefile` and `README.md`.
3. Open a Codespaces Terminal, make sure you're at the repository root (`cd /workspaces/$(basename "$PWD")` is NOT needed if already there) and run this **single command**:

```bash
unzip -oq ShrubTwitch-1.2-BuildFix.zip -d /tmp/shrubtwitch-v12fix && cp -a /tmp/shrubtwitch-v12fix/ShrubTwitch-main/. ./ && rm -f .github/workflows/build-dylib.yml .github/workflows/build-ipa.yml ShrubTwitch-1.2-BuildFix.zip && git add -A && (git diff --cached --quiet || git -c user.name="ShrubHub" -c user.email="shrubhub@users.noreply.github.com" commit -m "Fix ldid signing and speed up ShrubTwitch 1.2 IPA builds") && git push origin HEAD
```

The terminal returns after it has copied the files, committed changes and pushed them to your fork. It does NOT execute or require a PC/macOS build locally. **The command overwrites files with matching names** in your currently opened fork. Commit/backup any uncommitted work first.

Note: If `unzip` says the ZIP doesn't exist, use the exact filename shown in Codespaces Explorer and make sure it was uploaded into the repository root.

## 2. Configure your IPA URL once

1. Open your GitHub ShrubTwitch repository (not Codespaces) → **Settings**.
2. Choose **Secrets and variables → Actions → Variables**.
3. Press **New repository variable**.
4. Name: `TWITCH_IPA_URL` (uppercase, no spaces).
5. Value: an actual direct HTTPS URL to **your own decrypted Twitch IPA** (`.ipa`, ZIP-based). It must not be a webpage requiring clicking Download, an expiring temporary URL, or login cookies. Save.
6. If the URL contains a private token/password or you don't want it visible to repository maintainers, use the **Secrets** tab → New repository secret named `TWITCH_IPA_URL` **instead**. Use either variable or secret, not both (variable wins).

Only do this once as long as your file URL remains accessible. GitHub Actions will reuse it on subsequent runs. The IPA itself is intentionally NOT committed into GitHub source control.

## 3. Run/automate the IPA build

Go to **Actions → Build ShrubTwitch IPA → Run workflow → Run workflow**. Leave `ipa_url` blank. After a successful run open **Artifacts** and download **ShrubTwitch-IPA-[run]** (contains the unsigned patched IPA). A standalone dylib artifact is also uploaded.

When changes are pushed to `main` in `Sources/`, `Makefile`, the workflow/injector or the logo, the workflow also starts automatically. The IPA build is NOT triggered by README-only changes.

## 4. Build speed and signing notes

- First run can be slower as Theos, tools and dependencies are installed.
- Subsequent builds with unchanged source can skip compilation via a content-hashed `.dylib` cache; the IPA is still downloaded and repackaged each time.
- No script can guarantee a five-minute maximum: macOS runner queue, download speed, cache expiry and ZIP size vary.
- Resulting IPA is **not provisioned or signed with your personal distribution certificate**. It needs signing before installation on stock iOS.
- The workflow deliberately uploads the IPA as a short-retention Actions artifact, NOT a public GitHub Release. If your repository is public, understand that workflow artifacts and logs may be accessible according to GitHub permissions—consider this before supplying copyrighted app files.
- Keep the original GPLv3 license, attribution, and third-party notices when you publish the fork.

## 5. Where settings are

Open ShrubTwitch settings from the existing integrated entry. **Quick** opens quick actions. The optional floating menu button supports **long press** for Quick Panel. Chat Focus only affects the custom chat, and chat-density profiles require an active channel. Look in the native Control Center for the new feature pages.

## 6. Fix included after Error 127

- The previous workflow installed Homebrew `ldid` **after** `make`, but Theos signs the dylib as part of `make`.
- The fixed workflow installs and verifies `ldid` **before** compilation; also installs GNU Make in the same step when compiling.
- Uses a virtual environment with a prebuilt LIEF wheel for IPA injection to avoid Python's externally managed package errors.
- Cached `.dylib` builds bypass Theos setup and compilation; manual runs reuse your repository's saved `TWITCH_IPA_URL`.
- Fails early if the IPA URL is not configured. This addresses the reported error but does **not** guarantee five-minute builds or runtime compatibility.
- Older `build-dylib.yml` / `build-ipa.yml` workflows from upstream are removed by the install command to avoid confusing duplicate entries in Actions.
