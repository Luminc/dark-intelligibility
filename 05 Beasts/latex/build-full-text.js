// Build full Dark Intelligibility text with converted citations

const fs = require('fs');
const path = require('path');
const { convertCitations } = require('./convert-citations.js');

const CHAPTERS = [
  '../00 Companionability.md',
  '../01 The Between and Its Medicine.md',
  '../02 Metabolic Crisis.md',
  '../03 Dark Intelligibility.md'
  // Endnotes.md excluded - endnotes are auto-generated from citations
];

function buildFullText() {
  console.log('Building full Dark Intelligibility text...\n');

  let fullText = '';

  // Add YAML front matter for pandoc
  const today = new Date().toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });

  fullText += '---\n';
  fullText += 'title: "Dark Intelligibility"\n';
  fullText += 'subtitle: "The Pharmakon of Being"\n';
  fullText += 'author: "Jeroen Kortekaas"\n';
  fullText += `date: "${today}"\n`;
  fullText += 'reference-section-title: "References"\n';
  fullText += '---\n\n';

  // Add epigraph (with no page numbers/headers)
  fullText += '\\thispagestyle{empty}\n';
  fullText += '\\vspace*{\\fill}\n';
  fullText += '\\begin{center}\n';
  fullText += '\\textit{The greatest act of love for myself \\\\\n';
  fullText += 'is to look at my own pain.}\n';
  fullText += '\\end{center}\n';
  fullText += '\\vspace*{\\fill}\n\n';

  // Process each chapter
  for (const chapterPath of CHAPTERS) {
    const fullPath = path.join(__dirname, chapterPath);
    console.log(`Reading: ${chapterPath}`);

    if (!fs.existsSync(fullPath)) {
      console.error(`File not found: ${fullPath}`);
      continue;
    }

    let content = fs.readFileSync(fullPath, 'utf-8');

    // Convert citations
    content = convertCitations(content);

    // Add page break before each chapter (except first)
    if (fullText.length > 0 && !chapterPath.includes('Endnotes')) {
      fullText += '\n\\newpage\n\n';
    }

    fullText += content + '\n\n';
  }

  // Write output
  const outputPath = path.join(__dirname, 'dark-intelligibility-full.md');
  fs.writeFileSync(outputPath, fullText, 'utf-8');
  console.log(`\n✓ Generated: ${outputPath}`);
  console.log(`✓ Total length: ${fullText.length} characters`);

  return outputPath;
}

if (require.main === module) {
  buildFullText();
}

module.exports = { buildFullText };