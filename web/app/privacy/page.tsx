import fs from 'node:fs';
import path from 'node:path';

export default function Privacy() {
  const md = fs.readFileSync(path.join(process.cwd(), '..', 'PRIVACY.md'), 'utf8');
  return (
    <article className="prose max-w-2xl pt-12 pb-20">
      <pre className="whitespace-pre-wrap font-sans text-base leading-relaxed">{md}</pre>
    </article>
  );
}
