import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";

const ROOT = path.resolve(new URL("..", import.meta.url).pathname);
const OUT_DIR = path.join(ROOT, "app-store-screenshots", "ipad");
const DEVICE = process.env.IPAD_SIMULATOR_UDID ?? "D8D9B9A1-D267-492E-82FB-82FA61AB6990";
const BUNDLE_ID = "widlert.com.DinnerRandomizer";

const captures = [
  ["01-one-tap-dinner-ideas.png", "pasta-bacon-mushroom-sauce", "en"],
  ["02-fast-dinner-decisions.png", "fish-finger-tacos", "en"],
  ["03-ingredients-at-a-glance.png", "prawn-fried-noodles", "en"],
  ["05-real-family-meals.png", "chicken-ramen-bowls", "en"],
];

function run(command, args) {
  return execFileSync(command, args, { stdio: "inherit" });
}

function sleep(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

fs.mkdirSync(OUT_DIR, { recursive: true });

run("xcrun", ["simctl", "ui", DEVICE, "appearance", "light"]);
run("xcrun", [
  "simctl",
  "status_bar",
  DEVICE,
  "override",
  "--time",
  "22:12",
  "--dataNetwork",
  "wifi",
  "--wifiMode",
  "active",
  "--wifiBars",
  "3",
  "--cellularMode",
  "active",
  "--cellularBars",
  "0",
  "--batteryState",
  "discharging",
  "--batteryLevel",
  "100",
]);

for (const [file, dinnerId, language] of captures) {
  run("xcrun", [
    "simctl",
    "launch",
    "--terminate-running-process",
    DEVICE,
    BUNDLE_ID,
    "-screenshotDinner",
    dinnerId,
    "-screenshotLanguage",
    language,
  ]);
  await sleep(2500);
  run("xcrun", [
    "simctl",
    "io",
    DEVICE,
    "screenshot",
    "--mask",
    "ignored",
    path.join(OUT_DIR, file),
  ]);
}

run("xcrun", ["simctl", "status_bar", DEVICE, "clear"]);
