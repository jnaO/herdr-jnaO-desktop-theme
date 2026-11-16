// Theme release-channel events as toasts. tools/update writes the latest event to
// <Herdr home>/.jnao-theme/update.json as {id, outcome, tag, herdr, url, reason}.
// Each id toasts once across every copy and restart: the id last shown is kept
// in shared state.

import { appHome, checking, notify, readTextFile, setShared, shared, watchFolder } from "herdr";

const SEEN = "jnao-theme-update-seen";
const TAG = /^v[0-9][0-9.]*-r[0-9]+$/;
const VERSION = /^[0-9][0-9.]*$/;

const REASONS = {
  dirty: "The theme's clone has uncommitted changes. Commit or stash them; it tries again later.",
  diverged: "The theme's clone has commits of its own. Reset it to the published branch; it tries again later.",
  "no-herdr-version": "Herdr's version is not recorded yet. Restart Herdr once; it tries again then.",
  fetch: "The theme's releases could not be fetched. It tries again later.",
};

function toastFor(e) {
  const tag = TAG.test(e.tag ?? "") ? e.tag : "";
  const herdr = VERSION.test(e.herdr ?? "") ? e.herdr : "";
  switch (e.outcome) {
    case "installed":
      return tag && { level: "success", title: `Theme updated to ${tag}` };
    case "held":
      return tag && herdr && {
        level: "info",
        title: `Theme ${tag} is waiting for Herdr ${herdr}`,
        body: "Click to check for a Herdr update.",
        action: { name: "app.check_updates" },
      };
    case "rolled back":
      return {
        level: "error",
        title: tag ? `Theme ${tag} was rolled back` : "Theme update rolled back",
        body: "It failed after going live, so the previous theme is back. See update.log.",
      };
    case "blocked":
    case "failed":
      return REASONS[e.reason] && {
        level: "warning",
        title: e.outcome === "blocked" ? "Theme update blocked" : "Theme update failed",
        body: REASONS[e.reason],
      };
  }
  return null;
}

async function showLatest(file) {
  let e;
  try {
    e = JSON.parse(await readTextFile(file));
  } catch {
    return;
  }
  // The compare and the set stay in one synchronous step, so only one copy posts.
  if (!e || typeof e.id !== "string" || shared(SEEN) === e.id) return;
  setShared(SEEN, e.id);
  const toast = toastFor(e);
  if (toast) notify(toast);
}

export function watchUpdates(cx) {
  if (checking()) return;
  const dir = appHome() + "/.jnao-theme";
  cx.spawn(async () => {
    await showLatest(dir + "/update.json");
    for (;;) {
      try {
        await watchFolder(dir);
      } catch {
        return;
      }
      await showLatest(dir + "/update.json");
    }
  });
}
