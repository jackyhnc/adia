import type { MetadataRoute } from 'next';

const SITE = process.env.NEXT_PUBLIC_SITE_URL ?? 'https://adia.app';

export default function sitemap(): MetadataRoute.Sitemap {
  const now = new Date();
  return [
    { url: `${SITE}/`,          lastModified: now, changeFrequency: 'weekly',  priority: 1.0 },
    { url: `${SITE}/pricing`,   lastModified: now, changeFrequency: 'monthly', priority: 0.9 },
    { url: `${SITE}/download`,  lastModified: now, changeFrequency: 'weekly',  priority: 0.9 },
    { url: `${SITE}/changelog`, lastModified: now, changeFrequency: 'weekly',  priority: 0.5 },
    { url: `${SITE}/billing`,   lastModified: now, changeFrequency: 'yearly',  priority: 0.3 },
    { url: `${SITE}/privacy`,   lastModified: now, changeFrequency: 'yearly',  priority: 0.3 },
    { url: `${SITE}/terms`,     lastModified: now, changeFrequency: 'yearly',  priority: 0.3 },
  ];
}
