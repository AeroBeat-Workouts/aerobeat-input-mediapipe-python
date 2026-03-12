# Build Artifact Storage & Distribution Investigation

**Date:** 2026-02-07  
**Context:** AeroBeat game build storage and distribution strategy  
**Build Size:** ~200-400MB Linux bundles

---

## Executive Summary

For AeroBeat's current scale (indie/hobbyist), **GitHub Releases** is the recommended immediate solution. It offers free hosting, no bandwidth limits, and simple integration. As the user base grows, migrate to **AWS S3 + CloudFront** for better control and scalability.

---

## 1. Storage Options Comparison

### 1.1 Git + Git LFS

| Aspect | Details |
|--------|---------|
| **GitHub LFS Free Tier** | 10 GB storage, 10 GB bandwidth/month |
| **GitHub LFS File Limit** | 2 GB per file (up to 4 GB on some plans) |
| **Repository Size** | Recommended < 1 GB, strongly recommended < 5 GB |
| **Git Regular File Limit** | 100 MB (hard block), warnings at 50 MB |

**Pros:**
- Version control integrated with code
- Same access controls as repository
- File locking support for binaries

**Cons:**
- **NOT recommended for build artifacts** - only for source assets
- Bandwidth costs scale with team size
- Every clone downloads all history
- Pointer files can be confusing
- Storage costs increase over time

**Verdict:** ❌ **Avoid** for distribution builds. Use only for source assets (models, textures, audio).

---

### 1.2 GitHub Releases

| Aspect | Details |
|--------|---------|
| **File Size Limit** | 2 GB per file |
| **Total Release Size** | No limit |
| **Bandwidth** | Unlimited ("We don't limit the total size of binary files or bandwidth") |
| **Storage** | Free |
| **Retention** | Indefinite |

**Pros:**
- ✅ Completely FREE - no storage or bandwidth charges
- ✅ Simple drag-and-drop or CI/CD integration
- ✅ Version tags integrated with git
- ✅ Download counts and analytics
- ✅ Automatic release notes from commits
- ✅ Supports pre-release versions

**Cons:**
- 2 GB per file limit (not an issue for 200-400MB builds)
- No CDN (downloads from GitHub's servers)
- Less control over download experience
- No auto-updater integration out of the box

**Verdict:** ✅ **RECOMMENDED for AeroBeat's current scale**

---

### 1.3 itch.io

| Aspect | Details |
|--------|---------|
| **File Size Limit** | 1 GB per file (regular account) |
| **Files Per Page** | 10 max |
| **Bandwidth** | Unlimited |
| **Cost** | Free (pay-what-you-want, 10% revenue share if priced) |

**Pros:**
- Built for indie games
- Built-in community and discovery
- Can host browser-playable versions
- Simple upload process
- No bandwidth costs

**Cons:**
- 1GB limit may be restrictive for larger builds
- Platform focuses on discoverability, not just hosting
- Less professional than custom website
- Revenue share if you charge for the game

**Verdict:** ✅ **Good for community/visibility, not ideal for direct distribution control**

---

### 1.4 AWS S3 + CloudFront

| Aspect | Details |
|--------|---------|
| **S3 Storage** | $0.023/GB (first 50TB) |
| **S3 Requests** | $0.0004 per 1,000 GET requests |
| **Data Transfer OUT** | $0.09/GB (first 10TB) |
| **CloudFront** | $0.085/GB (first 10TB), free tier includes 1TB/month |
| **Free Tier** | 12 months: 5GB S3 + 15GB bandwidth/month |

**Pros:**
- Full control over storage and distribution
- CloudFront CDN for global low-latency downloads
- Presigned URLs for secure/private access
- Versioning and lifecycle policies
- Scales to any size
- Can implement custom auto-updater

**Cons:**
- Costs money (though modest at small scale)
- More complex setup
- Requires AWS knowledge
- Need to build download page/API

**Cost Estimates for AeroBeat:**
- **Storage:** 400MB × 10 versions = 4GB = ~$0.09/month
- **100 downloads/month:** 400MB × 100 = 40GB = ~$3.60/month
- **1,000 downloads/month:** 400GB = ~$36/month
- **With CloudFront:** Similar pricing but better performance

**Verdict:** ✅ **RECOMMENDED for production scale with >1000 users**

---

## 2. Recommended Approach

### Phase 1: Current State (Indie/Hobbyist)

**Use GitHub Releases**

```
Repository: aerobeat-community-linux (or keep in main repo)
```

**Workflow:**
1. Build Linux bundle in CI/CD (GitHub Actions)
2. Create release with semantic version tag (e.g., `v0.1.0`)
3. Attach build artifacts to release
4. Website links to latest release download

**Benefits:**
- Zero cost
- Zero maintenance
- Simple version tracking
- Users can download any version

---

### Phase 2: Growth (100+ active users)

**Add itch.io Mirror**
- Use for community engagement
- Backup distribution channel
- Free additional visibility

---

### Phase 3: Production Scale (1000+ users)

**Migrate to AWS S3 + CloudFront**

**Architecture:**
```
Website (GitHub Pages/Vercel)
    ↓ API Call
Version API (Lambda/Edge Function)
    ↓ Returns
Latest Version + Download URL
    ↓ Redirects
CloudFront CDN
    ↓ Serves
S3 Bucket (Build Storage)
```

---

## 3. AWS Architecture (Future State)

### 3.1 S3 Bucket Structure

```
aerobeat-builds/
├── latest.json                    # Current version metadata
├── versions/
│   ├── v0.1.0/
│   │   ├── aerobeat-linux-x64.tar.gz
│   │   ├── aerobeat-linux-x64.tar.gz.sha256
│   │   └── release-notes.md
│   ├── v0.1.1/
│   │   └── ...
│   └── v0.2.0/
│       └── ...
└── stable/
    └── aerobeat-linux-latest.tar.gz  # Symlink to latest stable
```

### 3.2 CloudFront Distribution

- **Origin:** S3 bucket
- **Behaviors:** 
  - Cache builds for 24 hours
  - Cache `latest.json` for 5 minutes
- **Price Class:** North America + Europe (cheaper)

### 3.3 Version API (Simple)

**Static JSON in S3** (no Lambda needed):

```json
{
  "latest": "0.2.1",
  "stable": "0.2.0",
  "platforms": {
    "linux": {
      "url": "https://cdn.aerobeat.io/v0.2.1/aerobeat-linux-x64.tar.gz",
      "size": 423456789,
      "checksum": "sha256:abc123..."
    }
  },
  "releaseNotes": "https://cdn.aerobeat.io/v0.2.1/release-notes.md"
}
```

---

## 4. Versioning Strategy

### Semantic Versioning for Games

```
MAJOR.MINOR.PATCH-build

Examples:
- 0.1.0-alpha1    # First alpha
- 0.1.0-beta1     # First beta  
- 0.1.0-rc1       # Release candidate
- 0.1.0           # Stable release
- 0.1.1           # Hotfix
- 0.2.0           # New features
- 1.0.0           # Full release
```

**Channels:**
- `stable` - Tested, recommended for all users
- `beta` - Feature-complete, needs testing
- `alpha` - Early access, may have bugs
- `nightly` - Latest development build

### Build Numbers

Include build number in CI:
```
v0.1.0+20250207.1  # Version + Date.Build
```

---

## 5. Distribution Architecture Options

### 5.1 Direct Download (Simplest)

**Flow:**
1. User visits website
2. Clicks "Download for Linux"
3. Browser downloads from GitHub/S3
4. User extracts and runs

**Pros:** Simple, universal  
**Cons:** No auto-update, users on old versions

---

### 5.2 Launcher with Auto-Updater

**Options:**

| Solution | Platform | Notes |
|----------|----------|-------|
| **Electron + electron-updater** | Cross-platform | Heavy, but feature-rich |
| **Squirrel.Windows** | Windows only | Native Windows updater |
| **Sparkle** | macOS only | Native macOS updater |
| **Custom HTTP updater** | Any | Check version JSON, download if newer |

**Simple Custom Updater Flow:**
```
Game Launch
    ↓
Check https://aerobeat.io/api/version
    ↓
Compare with local version
    ↓
If newer: Show "Update Available" dialog
    ↓
Download to temp, replace on restart
```

**Verdict for AeroBeat:** Start with direct download. Add simple "check for updates" later.

---

### 5.3 Delta Updates

**What:** Download only changed files, not entire build

**Tools:**
- **bsdiff** - Binary diff patches
- **courgette** (Google) - Optimized for executables
- **zsync** - rsync over HTTP

**When to Use:**
- Build size > 500MB
- Frequent small updates
- Large user base (bandwidth costs matter)

**Verdict for AeroBeat:** Overkill at current scale. Full downloads are fine for 200-400MB.

---

## 6. Website Integration

### 6.1 Detecting Latest Version

**Option A: GitHub Releases API (Free)**
```javascript
const response = await fetch(
  'https://api.github.com/repos/AeroBeat/aerobeat-community-linux/releases/latest'
);
const release = await response.json();
const downloadUrl = release.assets[0].browser_download_url;
```

**Option B: Static JSON (S3)**
```javascript
const response = await fetch('https://cdn.aerobeat.io/latest.json');
const data = await response.json();
const downloadUrl = data.platforms.linux.url;
```

### 6.2 Platform Detection

```javascript
function getPlatform() {
  const ua = navigator.userAgent;
  if (ua.includes('Linux')) return 'linux';
  if (ua.includes('Win')) return 'windows';
  if (ua.includes('Mac')) return 'mac';
  return 'linux'; // Default
}
```

### 6.3 Download Page Best Practices

1. **Primary CTA:** "Download for [Detected Platform]"
2. **Secondary:** "Other Platforms" dropdown
3. **Version Info:** Show version number prominently
4. **Release Notes:** Link to changelog
5. **Checksums:** Provide SHA256 for verification
6. **System Requirements:** List minimum specs
7. **Installation Instructions:** For Linux especially

---

## 7. Migration Path

### Current → Phase 1 (Now)
1. Set up GitHub Actions to build Linux bundle
2. Create release with version tag
3. Update website to link to GitHub Releases
4. Test download flow

### Phase 1 → Phase 3 (Future)
1. Create AWS account, set up S3 bucket
2. Configure CloudFront distribution
3. Set up CI/CD to upload to S3
4. Create `latest.json` generator
5. Update website to use new API
6. Maintain GitHub Releases as backup

---

## 8. Cost Comparison Summary

| Solution | Monthly Cost (100 DL) | Monthly Cost (1K DL) | Setup Complexity |
|----------|----------------------|---------------------|------------------|
| GitHub Releases | $0 | $0 | Low |
| itch.io | $0 | $0 | Low |
| AWS S3 only | ~$4 | ~$36 | Medium |
| S3 + CloudFront | ~$4 | ~$36 | Medium |
| Git LFS | $5+ (bandwidth) | $50+ | Low |

*Assumes 400MB build size*

---

## 9. Final Recommendations

### Immediate Actions (This Week)
1. ✅ **Use GitHub Releases** for build distribution
2. ✅ Create GitHub Action workflow for automated releases
3. ✅ Tag releases with semantic versions (v0.1.0, v0.1.1, etc.)

### Short Term (Next Month)
1. Add "Download" button to website using GitHub Releases API
2. Include checksums with each release
3. Write installation instructions for Linux users

### Medium Term (When Ready)
1. Consider itch.io for additional visibility
2. Implement simple "check for updates" in game
3. Monitor download metrics

### Long Term (If Scaling)
1. Migrate to AWS S3 + CloudFront
2. Implement launcher with auto-updater
3. Consider delta updates if builds grow >500MB

---

## Appendix: Example GitHub Action Workflow

```yaml
name: Build and Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build Linux Bundle
        run: |
          # Your build commands here
          tar -czf aerobeat-linux-x64.tar.gz build/
          sha256sum aerobeat-linux-x64.tar.gz > aerobeat-linux-x64.tar.gz.sha256
      
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            aerobeat-linux-x64.tar.gz
            aerobeat-linux-x64.tar.gz.sha256
          generate_release_notes: true
```

---

*Document generated for AeroBeat build distribution research.*
