# Noto Naskh Arabic Regular

Unmodified static TrueType font, version 2.019.

- Upstream: https://github.com/notofonts/arabic
- Copyright: 2022 The Noto Project Authors.
- License: SIL Open Font License 1.1; see OFL.txt and embedded font metadata.
- SHA-256: `2d5d78e9cc27d7193926c7e460314c9da7dbec1268494dbf117adc53c171ac06`.
- Imported from the existing Tor Browser 15.0.23 font bundle used by the
  native conformance tests; no outlines or OpenType tables were modified.

This is font data, not a shaping-library dependency. Production algorithms
remain ATS2. The application initializes this fallback before enabling its
native text session. `ANTHRACITE_ARABIC_FONT` can select an explicit alternate
static TrueType font; coverage and shaping capability then depend on that font.
