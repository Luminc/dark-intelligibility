# Citation Key System - Quick Reference

## Format: `[Author][page]`

Super short, non-intrusive, sortable, unique.

---

## Authors
- **D** = Desmond, *God and the Between* (2008)
- **Db** = Desmond, *Being and the Between* (1995) - if needed
- **N** = Nishitani, *Religion and Nothingness* (1982)
- **L** = Lispector, *The Passion According to G.H.* (Penguin 2014, trans. Idra Novey)
- **Lb** = Lispector, *A Breath of Life* (2012) - if needed
- **R** = Rilke, *New Poems* (1989)

---

## Examples in Text

### Current format (numbers):
```markdown
Desmond writes: "We clot on ourselves again."[^9]
```

### New format (short keys):
```markdown
Desmond writes: "We clot on ourselves again."[D331]
```

---

## In Your Endnotes File

### Old style:
```markdown
[^9]: Desmond, *God and the Between*, 331.
```

### New style:
```markdown
[D331]: Desmond, *God and the Between*, p. 331.
```

---

## Benefits

1. **No renumbering** - Add/remove/reorder freely
2. **Readable** - Know it's Desmond page 331 at a glance
3. **Brief** - Only 4-5 characters, doesn't interrupt flow
4. **Sortable** - Can organize endnotes by author or page
5. **Future-proof** - Can convert to full BibTeX later

---

## Usage Examples

```markdown
The metaxu[D41] is overdetermined[D78] space where being
communicates[D331] through porosity.

Nishitani describes sunyata[N138] as the field of the
Great Affirmation[N131] where emptiness is self[N138].

Lispector eats the white matter[L89] and undergoes
the metabolic crisis[L104].
```

Clean! Brief! No maintenance hell!

---

## When You Compile to LaTeX/PDF

Create a simple script or use Pandoc to convert:
- `[D331]` → proper Chicago/MLA footnote
- Auto-generate bibliography from your `references.bib`
- Get proper formatting without manual work

---

## Next Steps

1. ✅ Verified Desmond & Nishitani quotes (see `VERIFIED_CITATIONS.md`)
2. ⏳ Get Lispector page numbers (see `GH_QUOTES_TO_VERIFY.md`)
3. 🔄 Convert existing footnotes to short keys
4. ✍️ Write with short keys going forward