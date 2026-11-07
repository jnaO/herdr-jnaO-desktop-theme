// Machine identity: glass icon, tint, header row. Identical copy in jnao-spaces/ and jnao-agents/ (mods cannot import across folders).

import { div } from "gpui-kit";
import { h_flex } from "gpui-base";

// Glyphs are Nerd Font codepoints (Herdr bundles "Symbols Nerd Font"); tints are theme color names.
const KINDS = {
  laptop: { glyph: "\u{F0322}", tint: "ansi4" }, // nf-md-laptop
  mini: { glyph: "\u{F07C0}", tint: "ansi5" }, // nf-md-desktop_classic
  server: { glyph: "\u{F048B}", tint: "ansi3" }, // nf-md-server
};

// null is this computer (a MacBook Pro); remote machines go by name.
export function kind(name) {
  if (!name) return KINDS.laptop;
  return /mini|studio/i.test(name) ? KINDS.mini : KINDS.server;
}

export function machineColor(name, t) {
  return t[kind(name).tint] ?? t.accent;
}

export function machineIcon(name, size, t) {
  return div().flex_none().w(size + 4).flex().justify_center().font_family("Symbols Nerd Font").text_size(size).text_color(machineColor(name, t)).child(kind(name).glyph);
}

// Icon, upper-case name, a rule in the machine's tint, then `trailing` elements.
// Collapsed: the icon alone, centred.
export function machineHeader(id, name, t, { collapsed = false, trailing = [] } = {}) {
  const color = machineColor(name, t);
  const head = h_flex().id(id).h(32).flex_none().items_center().gap(8);
  if (collapsed) return head.justify_center().child(machineIcon(name, 17, t));
  return head.px(6)
    .child(machineIcon(name, 17, t))
    .child(div().flex_none().max_w(150).truncate().text_size(11.5).font_semibold().text_color(color).child((name ?? "This computer").toUpperCase()))
    .child(div().flex_1().min_w(12).h(1).bg(color + "4d"))
    .children(trailing);
}
