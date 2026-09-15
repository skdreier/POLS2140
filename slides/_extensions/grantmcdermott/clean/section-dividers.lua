-- section-dividers.lua
--
-- POLS 2140 house rule: every full-bleed section-break slide (a single `#`
-- heading, i.e. a level-1 Header, since these decks use slide-level: 2) gets
-- the standard slate contrast background automatically — no per-deck action,
-- no remembering, no separate checker script to run.
--
-- If a level-1 Header doesn't already carry a `background-color` attribute,
-- this injects the course default (`#2c3e50`). An explicit
-- `{background-color="..."}` the author already wrote is left untouched —
-- this only fills in the default, it never overrides a deliberate choice.
--
-- Companion to the CSS rule in clean.scss that auto-whites out body text on
-- any slide carrying `data-background-color="#2c3e50"` — between the two,
-- a bare `# Heading` needs zero extra markup to render correctly.

local DEFAULT_BG = "#2c3e50"

return {
  {
    Header = function(h)
      if h.level == 1 and h.attributes["background-color"] == nil then
        h.attributes["background-color"] = DEFAULT_BG
      end
      return h
    end,
  },
}
