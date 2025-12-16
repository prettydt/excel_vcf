# excel_vcf

## PWA Support

This site now includes Progressive Web App (PWA) support, allowing users to install it on their devices and use it offline.

### Features

- **Installable**: Add to Home Screen on iOS and Android devices
- **Offline Support**: Core functionality works without an internet connection
- **Standalone Mode**: Launches as a standalone app on mobile devices

### Deployment Configuration

The PWA is currently configured for deployment under the `/excel2Vcard/` subpath. All PWA asset paths include this prefix.

**Current deployment URL**: `https://excel-6gy76vkiabe8d352-1256290802.tcloudbaseapp.com/excel2Vcard/`

### Validation Steps

1. **Chrome DevTools**:
   - Open DevTools → Application tab
   - Check "Manifest" section: verify `start_url` is `/excel2Vcard/` and icons are detected
   - Check "Service Workers" section: verify the service worker is registered and activated
   - Run Lighthouse audit (PWA category): should pass "Installable" criteria

2. **iOS Safari**:
   - Visit the site on iPhone/iPad
   - Tap Share button → "Add to Home Screen"
   - Verify the icon appears correctly
   - Launch the app: should open as a standalone window (no browser UI)

3. **Android Chrome**:
   - Visit the site on Android device
   - Look for "Install app" prompt or menu option
   - Install and launch: should open as a standalone app

4. **Offline Test**:
   - Visit the site while online to cache assets
   - Enable Airplane mode or disconnect from network
   - Navigate to `/excel2Vcard/`: should load from cache
   - Navigation requests should fall back to cached `index.html`

### Path Configuration

If deploying to a different path or the domain root (`/`), update the following files:

1. **service-worker.js**:
   ```javascript
   const PREFIX = '/excel2Vcard';  // Change to '' for root or '/your-path' for another subpath
   ```

2. **manifest.webmanifest**:
   ```json
   "start_url": "/excel2Vcard/",  // Change to "/" for root
   "scope": "/excel2Vcard/",       // Change to "/" for root
   "icons": [/* update all icon paths */]
   ```

3. **index.html**:
   - Update `<link rel="manifest" href="/excel2Vcard/manifest.webmanifest">`
   - Update all icon link tags
   - Update service worker registration path in the script tag

### Files Added

- `manifest.webmanifest` - PWA manifest file with app metadata
- `service-worker.js` - Service worker for offline support and caching
- `icon-192.png` - App icon (192×192px)
- `icon-512.png` - App icon (512×512px)
- `maskable-512.png` - Maskable icon for adaptive icons (512×512px)

