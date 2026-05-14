import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";

const ROOT = path.resolve(new URL("..", import.meta.url).pathname);
const OUT_DIR = path.join(ROOT, "app-store-screenshots", "real-captures");
const BUNDLE_ID = "widlert.com.DinnerRandomizer";

const captures = [
  ["01-pasta.png", "pasta-bacon-mushroom-sauce", "en"],
  ["02-fish-tacos.png", "fish-finger-tacos", "en"],
  ["03-prawn-noodles.png", "prawn-fried-noodles", "en"],
  ["04-swedish-meatballs-sv.png", "swedish-meatballs", "sv"],
  ["05-ramen.png", "chicken-ramen-bowls", "en"],
];

function run(command, args, options = {}) {
  return execFileSync(command, args, {
    stdio: options.stdio ?? "inherit",
    ...options,
  });
}

function sleep(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

fs.mkdirSync(OUT_DIR, { recursive: true });

run("xcrun", [
  "simctl",
  "status_bar",
  "booted",
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
    "booted",
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
    "booted",
    "screenshot",
    "--mask",
    "ignored",
    path.join(OUT_DIR, file),
  ]);
}
