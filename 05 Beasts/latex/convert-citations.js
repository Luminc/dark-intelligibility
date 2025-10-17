// Convert custom citation format [L91] to pandoc format [@lispectorPassion2014, p. 91]

const fs = require('fs');

const citationMap = {
  // Lispector - The Passion According to G.H.
  'L': { key: 'lispectorPassion2014', title: 'The Passion According to G.H.' },
  // Desmond - God and the Between
  'D': { key: 'desmondGod2008', title: 'God and the Between' },
  // Desmond - Being and the Between
  'Db': { key: 'desmondBeing1995', title: 'Being and the Between' },
  // Nishitani - Religion and Nothingness
  'N': { key: 'nishitaniReligion1982', title: 'Religion and Nothingness' },
  // Rilke
  'R': { key: 'rilkeNewPoems1989', title: 'New Poems' },
};

function convertCitations(text) {
  // Pattern matches [L91], [D331], [N107-108], [Db-XX], etc.
  return text.replace(/\[([A-Z][a-z]?)(-?[0-9\-]+|[A-Za-z\-]+)\]/g, (match, prefix, page) => {
    const citation = citationMap[prefix];
    if (!citation) {
      console.warn(`Unknown citation prefix: ${prefix} in ${match}`);
      return match; // Keep original if unknown
    }

    // Handle special cases
    if (page.includes('youtube') || page.includes('XX')) {
      // Video or placeholder - just use citation key without page
      return `[@${citation.key}]`;
    }

    // Convert page format: "107-108" -> "pp. 107-108", "91" -> "p. 91"
    let pageStr;
    if (page.includes('-')) {
      pageStr = `pp. ${page}`;
    } else {
      pageStr = `p. ${page}`;
    }

    return `[@${citation.key}, ${pageStr}]`;
  });
}

function processFile(inputPath, outputPath) {
  const content = fs.readFileSync(inputPath, 'utf-8');
  const converted = convertCitations(content);
  fs.writeFileSync(outputPath, converted, 'utf-8');
  console.log(`Converted ${inputPath} -> ${outputPath}`);
}

module.exports = { convertCitations, processFile };

// CLI usage
if (require.main === module) {
  const [inputFile, outputFile] = process.argv.slice(2);
  if (!inputFile || !outputFile) {
    console.error('Usage: node convert-citations.js <input.md> <output.md>');
    process.exit(1);
  }
  processFile(inputFile, outputFile);
}
