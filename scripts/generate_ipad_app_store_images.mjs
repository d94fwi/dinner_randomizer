import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";

const ROOT = path.resolve(new URL("..", import.meta.url).pathname);
const SCREENSHOT_DIR = path.join(ROOT, "app-store-screenshots");
const SOURCE_DIR = path.join(SCREENSHOT_DIR, "ipad");
const OUT_DIR = path.join(SCREENSHOT_DIR, "ipad-app-store");
const WIDTH = 2064;
const HEIGHT = 2752;

const screens = [
  {
    file: "01-one-tap-dinner-ideas.png",
    source: "01-one-tap-dinner-ideas.png",
    eyebrow: "DINNER RANDOMIZER",
    title: ["Dinner ideas", "in one tap"],
    subtitle: "Shuffle through 100 practical meals when planning dinner stalls.",
    accent: "#f36f50",
    background: "#fff8ef",
  },
  {
    file: "02-fast-dinner-decisions.png",
    source: "02-fast-dinner-decisions.png",
    eyebrow: "FAST DECISIONS",
    title: ["Find tonight's", "dinner faster"],
    subtitle: "Browse family-friendly ideas with clear ingredients and serving notes.",
    accent: "#0f7d82",
    background: "#eef8f7",
  },
  {
    file: "03-ingredients-at-a-glance.png",
    source: "03-ingredients-at-a-glance.png",
    eyebrow: "SHOPPING CLARITY",
    title: ["Ingredients", "at a glance"],
    subtitle: "Every card is easy to scan before you shop or start cooking.",
    accent: "#c29232",
    background: "#f8f3e7",
  },
  {
    file: "05-real-family-meals.png",
    source: "05-real-family-meals.png",
    eyebrow: "NO ACCOUNT NEEDED",
    title: ["Real meals,", "zero planning fog"],
    subtitle: "A focused native iPad app for choosing tonight's dinner quickly.",
    accent: "#314b39",
    background: "#eff5f0",
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
  const sourcePath = path.join(SOURCE_DIR, file);
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
    size = 70,
    weight = 700,
    fill = "#111419",
    lineHeight = Math.round(size * 1.14),
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
    <circle cx="${WIDTH - 40}" cy="236" r="410" fill="${screen.accent}" opacity=".13"/>
    <circle cx="72" cy="${HEIGHT - 176}" r="360" fill="${screen.accent}" opacity=".10"/>
    <path d="M0 2190 C350 2055 700 2248 1030 2115 C1390 1970 1690 1945 2064 2036 L2064 2752 L0 2752 Z" fill="#ffffff" opacity=".50"/>
    <rect x="144" y="122" width="132" height="10" rx="5" fill="${screen.accent}"/>
  `;
}

function ipadCapture(screen) {
  const frameW = 1538;
  const frameH = 2051;
  const frameX = Math.round((WIDTH - frameW) / 2);
  const frameY = 638;
  const bezel = 36;
  const screenX = frameX + bezel;
  const screenY = frameY + bezel;
  const screenW = frameW - bezel * 2;
  const screenH = frameH - bezel * 2;
  const clipId = `${screen.file.replace(/[^a-z0-9]/gi, "-")}-clip`;
  const source = imageDataUri(screen.source);

  return `
    <g filter="url(#deviceShadow)">
      <rect x="${frameX}" y="${frameY}" width="${frameW}" height="${frameH}" rx="80" fill="#111416"/>
      <rect x="${frameX + 7}" y="${frameY + 7}" width="${frameW - 14}" height="${frameH - 14}" rx="73" fill="#2a2d2f"/>
      <clipPath id="${clipId}">
        <rect x="${screenX}" y="${screenY}" width="${screenW}" height="${screenH}" rx="50"/>
      </clipPath>
      <image x="${screenX}" y="${screenY}" width="${screenW}" height="${screenH}" href="${source}" preserveAspectRatio="xMidYMid slice" clip-path="url(#${clipId})"/>
    </g>
  `;
}

function buildSvg(screen) {
  return `<?xml version="1.0" encoding="UTF-8"?>
  <svg xmlns="http://www.w3.org/2000/svg" width="${WIDTH}" height="${HEIGHT}" viewBox="0 0 ${WIDTH} ${HEIGHT}">
    <defs>
      <filter id="deviceShadow" x="-18%" y="-12%" width="136%" height="132%">
        <feDropShadow dx="0" dy="34" stdDeviation="34" flood-color="#14202a" flood-opacity=".25"/>
      </filter>
    </defs>
    ${backdrop(screen)}
    ${textLines([screen.eyebrow], 144, 236, {
      size: 34,
      weight: 850,
      fill: screen.accent,
    })}
    ${textLines(screen.title, 144, 350, {
      size: 118,
      weight: 850,
      lineHeight: 124,
      fill: "#111419",
    })}
    ${textLines(wrapText(screen.subtitle, 56), 144, 576, {
      size: 45,
      weight: 500,
      fill: "#747a82",
      lineHeight: 58,
    })}
    ${ipadCapture(screen)}
  </svg>`;
}

fs.mkdirSync(OUT_DIR, { recursive: true });

for (const screen of screens) {
  const sourcePath = path.join(SOURCE_DIR, screen.source);
  if (!fs.existsSync(sourcePath)) {
    throw new Error(`Missing iPad simulator screenshot: ${sourcePath}`);
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
