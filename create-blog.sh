{\rtf1\ansi\ansicpg1252\cocoartf2822
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 #!/usr/bin/env bash\
set -euo pipefail\
\
mkdir -p jptwintails\
mkdir -p "jptwintails/posts" "jptwintails/public/covers"\
mkdir -p "jptwintails/lib" "jptwintails/app/admin" "jptwintails/app/signin"\
mkdir -p "jptwintails/app/posts/[slug]" "jptwintails/app/api/auth/[...nextauth]"\
\
# ---------- package.json ----------\
cat > jptwintails/package.json <<'EOF'\
\{\
  "name": "jptwintails",\
  "version": "0.1.0",\
  "private": true,\
  "scripts": \{\
    "dev": "next dev",\
    "build": "next build",\
    "start": "next start"\
  \},\
  "dependencies": \{\
    "next": "^15.1.0",\
    "react": "^19.0.0",\
    "react-dom": "^19.0.0"\
  \},\
  "devDependencies": \{\
    "typescript": "^5",\
    "@types/node": "^20",\
    "@types/react": "^19",\
    "@types/react-dom": "^19"\
  \}\
\}\
EOF\
\
# ---------- tsconfig.json ----------\
cat > jptwintails/tsconfig.json <<'EOF'\
\{\
  "compilerOptions": \{\
    "target": "ES2017",\
    "lib": ["dom", "dom.iterable", "esnext"],\
    "allowJs": true,\
    "skipLibCheck": true,\
    "strict": true,\
    "noEmit": true,\
    "esModuleInterop": true,\
    "module": "esnext",\
    "moduleResolution": "bundler",\
    "resolveJsonModule": true,\
    "isolatedModules": true,\
    "jsx": "preserve",\
    "incremental": true,\
    "plugins": [\{ "name": "next" \}],\
    "paths": \{ "@/*": ["./*"] \}\
  \},\
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],\
  "exclude": ["node_modules"]\
\}\
EOF\
\
# ---------- next.config.ts ----------\
cat > jptwintails/next.config.ts <<'EOF'\
import type \{ NextConfig \} from "next";\
\
const nextConfig: NextConfig = \{\};\
\
export default nextConfig;\
EOF\
\
# ---------- .gitignore ----------\
cat > jptwintails/.gitignore <<'EOF'\
node_modules\
.next\
out\
.env*.local\
.DS_Store\
*.tsbuildinfo\
next-env.d.ts\
EOF\
\
# ---------- .env.example ----------\
cat > jptwintails/.env.example <<'EOF'\
AUTH_GITHUB_ID=your-github-oauth-client-id\
AUTH_GITHUB_SECRET=your-github-oauth-client-secret\
AUTH_SECRET=openssl-rand-base64-32\
OWNER_GITHUB_USERNAME=your-github-username\
EOF\
\
# ---------- auth.ts ----------\
cat > jptwintails/auth.ts <<'EOF'\
import NextAuth from "next-auth";\
import GitHub from "next-auth/providers/github";\
\
export const \{ handlers, auth, signIn, signOut \} = NextAuth(\{\
  providers: [GitHub],\
  pages: \{ signIn: "/signin" \},\
  callbacks: \{\
    // only YOU get in \'97 your github username, nobody else\
    signIn(\{ profile \}) \{\
      return profile?.login === process.env.OWNER_GITHUB_USERNAME;\
    \},\
    // lock ONLY /admin. the whole blog stays public.\
    authorized(\{ auth, request \}) \{\
      const \{ pathname \} = request.nextUrl;\
      if (pathname.startsWith("/admin")) return !!auth;\
      return true; // everyone sees the blog\
    \},\
  \},\
\});\
EOF\
\
# ---------- middleware.ts ----------\
cat > jptwintails/middleware.ts <<'EOF'\
export \{ auth as middleware \} from "@/auth";\
\
export const config = \{\
  // Run auth on all pages except the auth API, static assets, and images.\
  matcher: ["/((?!api|_next/static|_next/image|favicon.ico|.*\\\\.(?:png|jpg|jpeg|gif|svg|webp|ico)$).*)"],\
\};\
EOF\
\
# ---------- lib/posts.ts ----------\
cat > jptwintails/lib/posts.ts <<'EOF'\
import fs from "fs";\
import path from "path";\
import matter from "gray-matter";\
import \{ marked \} from "marked";\
\
export type Post = \{\
  slug: string;\
  title: string;\
  date: string;\
  excerpt: string;\
  cover?: string;\
  contentHtml: string;\
\};\
\
const postsDir = path.join(process.cwd(), "posts");\
\
function readPosts(): Post[] \{\
  if (!fs.existsSync(postsDir)) return [];\
  return fs\
    .readdirSync(postsDir)\
    .filter((f) => f.endsWith(".md"))\
    .map((file) => \{\
      const raw = fs.readFileSync(path.join(postsDir, file), "utf8");\
      const \{ data, content \} = matter(raw);\
      const meta = data as Record<string, string>;\
      return \{\
        slug: file.replace(/\\.md$/, ""),\
        title: meta.title ?? file,\
        date: meta.date ?? "1970-01-01",\
        excerpt: meta.excerpt ?? "",\
        cover: meta.cover,\
        contentHtml: marked.parse(content) as string,\
      \};\
    \})\
    .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());\
\}\
\
export function getPosts(): Post[] \{\
  return readPosts();\
\}\
\
export function getPost(slug: string): Post | undefined \{\
  return readPosts().find((p) => p.slug === slug);\
\}\
EOF\
\
# ---------- app/layout.tsx ----------\
cat > jptwintails/app/layout.tsx <<'EOF'\
import type \{ Metadata \} from "next";\
import "./globals.css";\
\
export const metadata: Metadata = \{\
  title: \{ default: "JP TWINTAILS \'97 a fashion journal", template: "%s \'b7 JP TWINTAILS" \},\
  description: "raw fashion journal. est. 2025.",\
\};\
\
export default function RootLayout(\{ children \}: \{ children: React.ReactNode \}) \{\
  return (\
    <html lang="en">\
      <body>\{children\}</body>\
    </html>\
  );\
\}\
EOF\
\
# ---------- app/page.tsx ----------\
cat > jptwintails/app/page.tsx <<'EOF'\
import Link from "next/link";\
import \{ getPosts \} from "@/lib/posts";\
\
function fmt(d: string) \{\
  return new Date(d).toLocaleDateString("en-US", \{ year: "numeric", month: "short", day: "numeric" \});\
\}\
\
export default function HomePage() \{\
  const posts = getPosts();\
\
  return (\
    <main className="page wrap">\
      <p className="topbar">\
        <marquee>~*~ welcome 2 my fashion journal!!! est. 2025 ~*~ no haters allowed ~*~ run by the webmaster ~*~</marquee>\
      </p>\
\
      <header className="head">\
        <p className="tiny">LAST UPDATED: \{fmt(new Date().toISOString().split("T")[0])\} \'b7 800x600 OPTIMIZED</p>\
        <h1 className="blink">JP TWINTAILS</h1>\
        <p>a raw fashion journal on the world wide web <b>TM</b></p>\
        <hr className="double" />\
      </header>\
\
      <nav className="navlinks">\
        <a href="/">HOME</a> | <a href="/admin">WEBMASTER LOGIN</a>\
      </nav>\
      <hr className="dots" />\
\
      <section>\
        <h2>~*~ LATEST POSTS ~*~</h2>\
        <table className="postlist">\
          <tbody>\
            \{posts.map((p) => (\
              <tr key=\{p.slug\}>\
                <td className="date">[\{fmt(p.date)\}]</td>\
                <td>\
                  <Link href=\{`/posts/$\{p.slug\}`\}><b>\{p.title\}</b></Link>\
                  \{p.excerpt && <span className="muted"> \'97 \{p.excerpt\}</span>\}\
                </td>\
              </tr>\
            ))\}\
          </tbody>\
        </table>\
        \{posts.length === 0 && <p className="muted">no posts yet!! add .md files to /posts and push.</p>\}\
      </section>\
\
      <hr className="dots" />\
      <footer className="foot">\
        <p>visitor counter: [ 0000\{posts.length\} ]</p>\
        <p className="tiny">made with notepad + a dream \'b7 best viewed in netscape navigator 3.0 \'b7 \'a9 \{new Date().getFullYear()\} the webmaster</p>\
        <p className="tiny"><a href="/admin">[*] click here if u r the webmaster, i will know]</a></p>\
      </footer>\
    </main>\
  );\
\}\
EOF\
\
# ---------- app/posts/[slug]/page.tsx ----------\
cat > "jptwintails/app/posts/[slug]/page.tsx" <<'EOF'\
import Link from "next/link";\
import \{ notFound \} from "next/navigation";\
import \{ getPost \} from "@/lib/posts";\
\
export const dynamic = "force-dynamic";\
\
function fmt(d: string) \{\
  return new Date(d).toLocaleDateString("en-US", \{ year: "numeric", month: "long", day: "numeric" \});\
\}\
\
export default async function PostPage(\{ params \}: \{ params: Promise<\{ slug: string \}> \}) \{\
  const \{ slug \} = await params;\
  const post = getPost(slug);\
  if (!post) notFound();\
\
  return (\
    <main className="page wrap">\
      <p className="topbar"><marquee>~*~ u r reading: \{post.title\} ~*~ thx 4 stopping by ~*~</marquee></p>\
      <header className="head">\
        <p className="tiny">JP TWINTAILS \'97 FASHION JOURNAL</p>\
        <h1>\{post.title\}</h1>\
        <p className="muted">posted: \{fmt(post.date)\} by webmaster</p>\
        <hr className="double" />\
      </header>\
\
      \{post.cover && <img src=\{post.cover\} alt="" className="postimg" />\}\
\
      <article className="prose" dangerouslySetInnerHTML=\{\{ __html: post.contentHtml \}\} />\
\
      <hr className="dots" />\
      <p>\
        <Link href="/">[ &lt;&lt; back to the homepage ]</Link> &nbsp; <a href="/admin">[ webmaster login ]</a>\
      </p>\
      <footer className="foot tiny">\
        <p>\'a9 \{new Date().getFullYear()\} the webmaster \'b7 this page looks best in netscape</p>\
      </footer>\
    </main>\
  );\
\}\
EOF\
\
# ---------- app/signin/page.tsx ----------\
cat > jptwintails/app/signin/page.tsx <<'EOF'\
"use client";\
\
import \{ signIn \} from "next-auth/react";\
\
export default function SignInPage() \{\
  return (\
    <main className="page wrap">\
      <h1 className="blink">WEBMASTER ONLY!!!</h1>\
      <hr className="double" />\
      <p>\
        heyy, this here is the <b>control room</b>. u must be the webmaster (me).\
        if ur not me \'97 get lost!!\
      </p>\
      <p className="muted">\
        (login uses github. if ur github username aint the owner's, the door slams shut.)\
      </p>\
      <button className="oldbtn" onClick=\{() => signIn("github", \{ callbackUrl: "/admin" \})\}>\
        &gt;&gt; CLICK 2 SIGN IN WITH GITHUB &lt;&lt;\
      </button>\
      <p className="tiny">\
        <a href="/">&lt;&lt; nvm i changed my mind, take me 2 the blog &gt;&gt;</a>\
      </p>\
    </main>\
  );\
\}\
EOF\
\
# ---------- app/admin/page.tsx ----------\
cat > jptwintails/app/admin/page.tsx <<'EOF'\
import Link from "next/link";\
import \{ redirect \} from "next/navigation";\
import \{ auth \} from "@/auth";\
import \{ getPosts \} from "@/lib/posts";\
\
export default async function AdminPage() \{\
  const session = await auth();\
  if (!session?.user) redirect("/signin");\
\
  const posts = getPosts();\
\
  return (\
    <main className="page wrap">\
      <h1 className="blink">*** WEBMASTER CONTROL ROOM ***</h1>\
      <p>LOGGED IN AS: <b>\{session.user.name\}</b> &lt;\{session.user.email\}&gt;</p>\
      <hr className="double" />\
\
      <h2>~*~ ALL POSTS (\{posts.length\}) ~*~</h2>\
      <table className="postlist">\
        <tbody>\
          \{posts.map((p) => (\
            <tr key=\{p.slug\}>\
              <td className="date">[\{p.date\}]</td>\
              <td><Link href=\{`/posts/$\{p.slug\}`\}>\{p.title\}</Link></td>\
            </tr>\
          ))\}\
        </tbody>\
      </table>\
\
      <p className="muted">\
        want a new post? drop a .md file into the /posts folder, push 2 github, and it shows up. that's the whole cms lol.\
      </p>\
\
      <hr className="dots" />\
      <p>\
        <a href="/">&lt;&lt; view the blog</a> &nbsp;|&nbsp;\
        <a className="oldbtn" href="/api/auth/signout">SIGN OUT</a>\
      </p>\
    </main>\
  );\
\}\
EOF\
\
# ---------- app/api/auth/[...nextauth]/route.ts ----------\
cat > "jptwintails/app/api/auth/[...nextauth]/route.ts" <<'EOF'\
import \{ handlers \} from "@/auth";\
\
export const \{ GET, POST \} = handlers;\
EOF\
\
# ---------- app/globals.css ----------\
cat > jptwintails/app/globals.css <<'EOF'\
:root \{\
  --bg: #000;\
  --fg: #d0d0d0;\
  --head: #ffff00;\
  --link: #00ff66;\
  --linkv: #ff66ff;\
  --muted: #888;\
  --line: #555;\
\}\
\
* \{ box-sizing: border-box; \}\
\
body \{\
  margin: 0;\
  background: var(--bg);\
  background-image:\
    linear-gradient(rgba(0, 255, 102, .03) 1px, transparent 1px),\
    linear-gradient(90deg, rgba(0, 255, 102, .03) 1px, transparent 1px);\
  background-size: 24px 24px;\
  color: var(--fg);\
  font-family: "Times New Roman", Times, serif;\
  font-size: 17px;\
  line-height: 1.6;\
  cursor: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='16' height='24'><polygon points='0,0 0,24 6,16 12,15 16,12 12,9 10,4' fill='lime'/></svg>") 0 0, auto;\
\}\
\
a \{ color: var(--link); \}\
a:visited \{ color: var(--linkv); \}\
\
.wrap \{ max-width: 860px; margin: 0 auto; padding: 0 20px; \}\
.muted \{ color: var(--muted); \}\
.tiny \{ font-size: 11px; color: var(--muted); \}\
\
h1, h2, h3 \{ color: var(--head); font-family: "Comic Sans MS", "Comic Sans", cursive; \}\
h1 \{ font-size: 48px; text-decoration: underline; margin: 16px 0; \}\
h2 \{ font-size: 24px; text-decoration: underline; \}\
\
.blink \{ animation: blink 1.1s steps(2, start) infinite; \}\
@keyframes blink \{ 50% \{ opacity: 0; \} \}\
\
.topbar \{ border: 2px double var(--line); background: #0a0a0a; margin: 10px 0; padding: 4px; \}\
marquee \{ color: var(--head); font-size: 14px; \}\
\
.head \{ text-align: center; padding: 24px 0 8px; \}\
.double \{ border: none; border-top: 4px double var(--line); margin: 16px 0; \}\
.dots \{ border: none; border-top: 1px dotted var(--line); margin: 18px 0; \}\
\
.navlinks \{ text-align: center; font-size: 14px; letter-spacing: .08em; \}\
.navlinks a \{ text-decoration: none; \}\
\
.postlist \{ width: 100%; border-collapse: collapse; \}\
.postlist td \{ border: 1px solid var(--line); padding: 10px 12px; \}\
.postlist tr:nth-child(odd) \{ background: #050505; \}\
.date \{ white-space: nowrap; color: var(--muted); font-size: 13px; \}\
\
.postimg \{ max-width: 100%; border: 3px double var(--line); margin: 12px 0; \}\
\
.prose \{ margin-top: 12px; \}\
.prose h2 \{ margin-top: 28px; \}\
.prose img \{ max-width: 100%; border: 3px double var(--line); \}\
.prose blockquote \{ border-left: 3px solid var(--line); margin: 20px 0; padding-left: 14px; color: var(--muted); font-style: italic; \}\
.prose hr \{ border: none; border-top: 1px dotted var(--line); margin: 28px 0; \}\
.prose ul, .prose ol \{ padding-left: 24px; \}\
\
.foot \{ text-align: center; padding: 20px 0 40px; \}\
\
.oldbtn \{\
  display: inline-block; margin: 8px 0;\
  background: #000; color: var(--head);\
  border: 3px outset #777; padding: 8px 16px;\
  font-family: "Comic Sans MS", cursive; font-size: 14px;\
  text-decoration: none; cursor: pointer;\
\}\
.oldbtn:active \{ border-style: inset; \}\
\
h1.blink \{ font-size: 64px; \}\
EOF\
\
# ---------- posts/hello-world.md ----------\
cat > jptwintails/posts/hello-world.md <<'EOF'\
---\
title: "First entry"\
date: "2025-01-10"\
excerpt: "Welcome to the private journal \'97 first thoughts on this season."\
cover: "/covers/hello.jpg"\
---\
\
Welcome to my private fashion journal. This space is just for me.\
\
## A note on this season\
\
Some slow-fashion musings go here. Write in plain markdown \'97 headings, lists, quotes and images all just work.\
\
> Style is a way to say who you are without having to speak.\
\
Any link to get back: **[the journal](/)**.\
EOF\
\
# ---------- README.md ----------\
cat > jptwintails/README.md <<'EOF'\
# JP TWINTAILS \'97 raw fashion blog\
\
Public blog, retro look. Only /admin is locked behind a GitHub login (owner only).\
\
## Run locally\
1. `npm install`\
2. `npm install next-auth@beta gray-matter marked`\
3. `cp .env.example .env.local` and fill in values\
4. `npm run dev` \uc0\u8594  http://localhost:3000\
\
## Deploy\
Push to GitHub \uc0\u8594  import in Vercel \u8594  add domain `jptwintails.site` \u8594 \
set the 4 env vars \uc0\u8594  point DNS at Vercel.\
EOF\
\
echo "\uc0\u10004  Project created in ./jptwintails"\
echo "Next: cd jptwintails && npm install && npm install next-auth@beta gray-matter marked"\
}