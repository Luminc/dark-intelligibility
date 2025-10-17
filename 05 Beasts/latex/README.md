# Dark Intelligibility - PDF Export Pipeline

This directory contains the automated LaTeX export pipeline for generating the complete "Dark Intelligibility" manuscript as a professionally typeset PDF.

## Overview

The pipeline converts markdown chapters with custom citations into a fully formatted PDF with:
- Custom typography (Noto Sans Light with multilingual support)
- Endnotes automatically generated from citations
- Table of contents
- Professional chapter layout with right-aligned titles
- References section with Chicago note-bibliography style

## Quick Start

```bash
npm run build-full
```

This will:
1. Combine all chapters into a single markdown file
2. Convert custom citations (e.g., `[L91]`) to pandoc format
3. Generate PDF with XeLaTeX including endnotes and bibliography

Output: `Dark_Intelligibility.pdf`

## File Structure

### Core Files
- **`build-full-text.js`** - Main build script that combines chapters
- **`convert-citations.js`** - Converts custom citation format to pandoc format
- **`template-book.tex`** - LaTeX template with all typography and layout settings
- **`references.bib`** - Zotero bibliography file

### Generated Files
- **`dark-intelligibility-full.md`** - Intermediate markdown file (auto-generated)
- **`Dark_Intelligibility.pdf`** - Final PDF output

### Configuration
- **`package.json`** - Node.js dependencies and build scripts

## Citation System

### Custom Citation Format
In the markdown chapters, use the shorthand format:
```markdown
[L91]          → Lispector, page 91
[D331]         → Desmond (God and the Between), page 331
[Db-XX]        → Desmond (Being and the Between), no page
[N107-108]     → Nishitani, pages 107-108
```

### Citation Mapping
Defined in `convert-citations.js`:
- `L` → `lispectorPassion2014` (The Passion According to G.H.)
- `D` → `desmondGod2008` (God and the Between)
- `Db` → `desmondBeing1995` (Being and the Between)
- `N` → `nishitaniReligion1982` (Religion and Nothingness)
- `R` → `rilkeNewPoems1989` (New Poems)

### Adding New Citations
1. Add entry to `references.bib`
2. Add mapping to `citationMap` in `convert-citations.js`
3. Use new prefix in markdown chapters

## Typography Settings

All typography is configured in `template-book.tex`:

### Body Text
- **Font**: Noto Sans Light (0.95 scale)
- **Size**: 9pt
- **Line height**: 18pt
- **Letter-spacing**: 25/1000 em
- **Paragraphs**: 1.5em indent, no spacing between

### Multilingual Support
- **Latin/Greek**: Noto Sans
- **Japanese/CJK**: Noto Sans JP (via xeCJK package)

### Chapter Layout
- **Position**: 40% down page (~middle)
- **Alignment**: Right-aligned
- **Size**: 28pt
- **Format**: Unnumbered, each starts on new page

### Endnotes
- **Format**: "77. Author, Title, page"
- **Line height**: 18pt (matches body)
- **Indent**: 2em hanging indent
- **In-text**: Superscript numbers

### Title Page
- **Title**: 32pt, bold, right-aligned
- **Subtitle**: 20pt, medium gray
- **Author**: 16pt
- **No "by" prefix**

## Chapter Structure

The build includes these chapters (defined in `build-full-text.js`):
1. `00 Companionability and Possession.md`
2. `01 The Pharmakon and the Metaxu.md`
3. `02 The Violence of Grace.md`
4. `03 Dark Intelligibility.md`

Endnotes.md is excluded as endnotes are auto-generated from citations.

## Requirements

### Software
- **Node.js** - For build scripts
- **Pandoc** - Document converter
- **XeLaTeX** - LaTeX engine with font support
- **MiKTeX** or **TeX Live** - LaTeX distribution

### Fonts
- **Noto Sans** (Light, Medium variants)
- **Noto Sans JP** (for Japanese characters)

Install via font manager or download from Google Fonts.

## Customization

### Adjusting Typography
Edit `template-book.tex`:
- **Font size**: Line 42 `\fontsize{9}{18}`
- **Line height**: Second number in fontsize
- **Margins**: Line 7 `geometry` package settings
- **Letter-spacing**: Line 47 `\SetTracking`

### Modifying Chapter Layout
Edit `template-book.tex`:
- **Chapter position**: Line 61 `\titlespacing*{\chapter}{0pt}{0.40\textheight}{0pt}`
- **Chapter alignment**: Line 54 `\raggedleft` (right), `\raggedright` (left), or `\centering`
- **Chapter size**: Line 54 `\fontsize{28}{36}`

### Adding/Removing Chapters
Edit `build-full-text.js` line 7-12:
```javascript
const CHAPTERS = [
  '../00 Companionability and Possession.md',
  // Add new chapters here
];
```

## Build Process Details

1. **Markdown Generation** (`build-full-text.js`)
   - Reads each chapter file
   - Converts citations via `convert-citations.js`
   - Adds YAML frontmatter
   - Combines into single markdown

2. **Pandoc Conversion**
   - Processes citations with `--citeproc`
   - Applies Chicago note-bibliography style
   - Uses custom LaTeX template
   - Generates endnotes automatically

3. **XeLaTeX Compilation**
   - Renders fonts with fontspec
   - Creates table of contents
   - Formats endnotes section
   - Generates References chapter
   - Outputs final PDF

## Troubleshooting

### Missing Character Warnings
Install additional Noto Sans variants (CJK, Symbols, etc.) for full Unicode support.

### Font Not Found
Ensure Noto Sans and Noto Sans JP are installed system-wide, not just user-local.

### Build Errors
Check:
- All chapter files exist in parent directory
- `references.bib` contains all cited works
- Pandoc and XeLaTeX are in system PATH

### Bibliography Issues
Ensure citation keys in `convert-citations.js` match those in `references.bib`.

## Version History

- **October 2025** - Initial pipeline with custom typography and citation system

## License

Copyright © 2025 Jeroen Kortekaas
