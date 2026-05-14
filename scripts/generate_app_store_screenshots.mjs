import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";

const ROOT = path.resolve(new URL("..", import.meta.url).pathname);
const SCREENSHOT_DIR = path.join(ROOT, "app-store-screenshots");
const OUT_DIR = path.join(SCREENSHOT_DIR, "final");
const CAPTURE_DIR = path.join(SCREENSHOT_DIR, "real-captures");
const WIDTH = 1242;
const HEIGHT = 2688;

const screens = [
  {
    file: "01-one-tap-dinner-ideas.png",
    capture: "01-pasta.png",
    eyebrow: "DINNER RANDOMIZER",
    title: ["Dinner ideas", "in one tap"],
    subtitle: "Shuffle through 100 practical meals when planning dinner stalls.",
    accent: "#f36f50",
    background: "#fff8ef",
    phoneY: 686,
  },
  {
    file: "02-fast-dinner-decisions.png",
    capture: "02-fish-tacos.png",
    eyebrow: "FAST DECISIONS",
    title: ["Find tonight's", "dinner faster"],
    subtitle: "Browse family-friendly ideas with clear ingredients and serving notes.",
    accent: "#0f7d82",
    background: "#eef8f7",
    phoneY: 702,
  },
  {
    file: "03-ingredients-at-a-glance.png",
    capture: "03-prawn-noodles.png",
    eyebrow: "SHOPPING CLARITY",
    title: ["Ingredients", "at a glance"],
    subtitle: "Every card is easy to scan before you shop or start cooking.",
    accent: "#c29232",
    background: "#f8f3e7",
    phoneY: 690,
  },
  {
    file: "04-localized-meal-ideas.png",
    capture: "04-swedish-meatballs-sv.png",
    eyebrow: "LOCALIZED",
    title: ["Meal ideas in", "four languages"],
    subtitle: "Use English, svenska, norsk, or polski with localized dinner text.",
    accent: "#17324d",
    background: "#edf3fb",
    phoneY: 702,
  },
  {
    file: "05-real-family-meals.png",
    capture: "05-ramen.png",
    eyebrow: "NO ACCOUNT NEEDED",
    title: ["Real meals,", "zero planning fog"],
    subtitle: "A focused native app for choosing tonight's dinner quickly.",
    accent: "#314b39",
    background: "#eff5f0",
    phoneY: 686,
  },
];

function esc(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function imageDataUri(file) {
  const sourcePath = path.join(CAPTURE_DIR, file);
  const bytes = fs.readFileSync(sourcePath);
  return `data:image/png;base64,${bytes.toString("base64")}`;
}

function wrapText(text, maxChars) {
  const words = String(text).split(/\s+/);
  const lines = [];
  let line = "";

  for (const word of words) {
    const next = line ? `${line} ${word}` : word;
    if (next.length > maxChars && line) {
      lines.push(line);
      line = word;
    } else {
      line = next;
    }
  }

  if (line) lines.push(line);
  return lines;
}

function textLines(lines, x, y, options = {}) {
  const {
    size = 48,
    weight = 700,
    fill = "#111419",
    lineHeight = Math.round(size * 1.16),
    anchor = "start",
    opacity = 1,
  } = options;

  return `<text x="${x}" y="${y}" text-anchor="${anchor}" fill="${fill}" opacity="${opacity}" font-family="SF Pro Display, -apple-system, BlinkMacSystemFont, Helvetica Neue, Arial, sans-serif" font-size="${size}" font-weight="${weight}" letter-spacing="0">${lines
    .map((line, index) => `<tspan x="${x}" dy="${index === 0 ? 0 : lineHeight}">${esc(line)}</tspan>`)
    .join("")}</text>`;
}

function backdrop(screen) {
  return `
    <rect width="${WIDTH}" height="${HEIGHT}" fill="${screen.background}"/>
    <circle cx="${WIDTH - 46}" cy="220" r="260" fill="${screen.accent}" opacity=".14"/>
    <circle cx="70" cy="${HEIGHT - 190}" r="258" fill="${screen.accent}" opacity=".10"/>
    <path d="M0 2140 C230 2030 430 2178 650 2074 C884 1964 1018 1880 1242 1934 L1242 2688 L0 2688 Z" fill="#ffffff" opacity=".48"/>
    <rect x="92" y="108" width="90" height="8" rx="4" fill="${screen.accent}"/>
  `;
}

function phoneCapture(screen) {
  const frameW = 872;
  const frameH = 1888;
  const frameX = Math.round((WIDTH - frameW) / 2);
  const frameY = screen.phoneY - 34;
  const bezel = 34;
  const phoneW = frameW - bezel * 2;
  const phoneH = frameH - bezel * 2;
  const phoneX = frameX + bezel;
  const phoneY = frameY + bezel;
  const capture = imageDataUri(screen.capture);
  const clipId = `${screen.file.replace(/[^a-z0-9]/gi, "-")}-clip`;

  return `
    <g filter="url(#phoneShadow)">
      <rect x="${frameX}" y="${frameY}" width="${frameW}" height="${frameH}" rx="116" fill="#101416"/>
      <rect x="${frameX + 8}" y="${frameY + 8}" width="${frameW - 16}" height="${frameH - 16}" rx="108" fill="#2a2d2f"/>
      <clipPath id="${clipId}">
        <rect x="${phoneX}" y="${phoneY}" width="${phoneW}" height="${phoneH}" rx="88"/>
      </clipPath>
      <image x="${phoneX}" y="${phoneY}" width="${phoneW}" height="${phoneH}" href="${capture}" preserveAspectRatio="xMidYMid slice" clip-path="url(#${clipId})"/>
    </g>
  `;
}

function buildSvg(screen) {
  return `<?xml version="1.0" encoding="UTF-8"?>
  <svg xmlns="http://www.w3.org/2000/svg" width="${WIDTH}" height="${HEIGHT}" viewBox="0 0 ${WIDTH} ${HEIGHT}">
    <defs>
      <filter id="phoneShadow" x="-20%" y="-12%" width="140%" height="132%">
        <feDropShadow dx="0" dy="34" stdDeviation="30" flood-color="#14202a" flood-opacity=".26"/>
      </filter>
    </defs>
    ${backdrop(screen)}
    ${textLines([screen.eyebrow], 92, 212, {
      size: 27,
      weight: 850,
      fill: screen.accent,
    })}
    ${textLines(screen.title, 92, 308, {
      size: 84,
      weight: 850,
      lineHeight: 92,
      fill: "#111419",
    })}
    ${textLines(wrapText(screen.subtitle, 43), 92, 520, {
      size: 34,
      weight: 500,
      fill: "#747a82",
      lineHeight: 44,
    })}
    ${phoneCapture(screen)}
  </svg>`;
}

fs.mkdirSync(OUT_DIR, { recursive: true });

for (const screen of screens) {
  const capturePath = path.join(CAPTURE_DIR, screen.capture);
  if (!fs.existsSync(capturePath)) {
    throw new Error(`Missing real simulator capture: ${capturePath}`);
  }

  const svgPath = path.join(OUT_DIR, screen.file.replace(".png", ".svg"));
  const pngPath = path.join(OUT_DIR, screen.file);

  fs.writeFileSync(svgPath, buildSvg(screen));
  execFileSync("rsvg-convert", [
    "--width",
    String(WIDTH),
    "--height",
    String(HEIGHT),
    "--format",
    "png",
    "--output",
    pngPath,
    svgPath,
  ]);
  fs.rmSync(svgPath);
  console.log(pngPath);
}
