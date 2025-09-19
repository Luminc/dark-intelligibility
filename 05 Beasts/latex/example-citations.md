# Example: New Citation Format

Instead of manual footnotes like this:
```markdown
"The neutral was what was intimate."[^1]

[^1]: Clarice Lispector, _The Passion According to G.H._, p. 78.
```

You now write:
```markdown
"The neutral was what was intimate."[@lispector2012passion, p. 78]
```

## Benefits:
- **Auto-formatting**: Citations format automatically
- **Auto-bibliography**: Reference list generates automatically
- **Consistency**: No manual footnote numbering
- **Zotero integration**: Insert citations directly from your library

## Citation Syntax:
- `[@key]` - Basic citation
- `[@key, p. 123]` - With page number
- `[@key1; @key2]` - Multiple sources
- `-@key` - Suppress author name
- `@key says...` - In-text author name

## Your VS Code Workflow:
1. **Ctrl+Shift+P** → "Citation Picker"
2. Search for source in Zotero
3. Insert citation key automatically
4. **npm run build** → Professional PDF with proper citations