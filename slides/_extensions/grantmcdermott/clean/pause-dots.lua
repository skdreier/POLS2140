-- pause-dots.lua
--
-- Makes ". . ." (three dots, spaces between them, on its own line) a real
-- reveal.js pause: everything from that point until the next ". . ." (or the
-- end of the slide/container) gets wrapped in a `.fragment` div, so it
-- reveals on click.
--
-- Works in: plain slide markdown, inside Pandoc `::: {...}` fenced divs, and
-- inside `layout=` panel columns.
--
-- Does NOT touch a ". . ." found inside a raw HTML `<div>...</div>` block —
-- wrapping across a raw div's own open/close tags there can produce
-- malformed nested HTML, so that case is intentionally left alone and a
-- build-time warning is printed instead of silently failing. Use an explicit
-- `.fragment` div in that situation (see the cheat sheet).

local function is_dots_para(block)
  if block == nil then return false end
  if block.t ~= "Para" and block.t ~= "Plain" then return false end
  local text = pandoc.utils.stringify(block)
  text = text:gsub("^%s+", ""):gsub("%s+$", "")
  return text == ". . ." or text == "..."
end

-- +1 if this RawBlock opens one or more raw HTML <div>s, -1 per </div>, so we
-- can track whether we're currently inside a raw HTML div.
local function raw_div_delta(block)
  if block.t ~= "RawBlock" or block.format ~= "html" then return 0 end
  local text = block.text
  local opens, closes = 0, 0
  for _ in text:gmatch("<div[%s>]") do opens = opens + 1 end
  for _ in text:gmatch("</div>") do closes = closes + 1 end
  return opens - closes
end

-- Split a flat list of blocks on top-level ". . ." markers into fragment
-- groups. Returns a new flat list of blocks (unchanged if no markers found).
local function split_dots(blocks)
  local groups = { {} }
  local depth = 0
  local any_dots = false
  local any_skipped = false

  for _, b in ipairs(blocks) do
    depth = depth + raw_div_delta(b)
    if is_dots_para(b) and depth == 0 then
      any_dots = true
      table.insert(groups, {})
    else
      if is_dots_para(b) and depth > 0 then
        any_skipped = true
      end
      table.insert(groups[#groups], b)
    end
  end

  if any_skipped and quarto and quarto.log then
    quarto.log.warning("pause-dots.lua: found '. . .' inside a raw HTML <div> — left as literal text. Use an explicit '.fragment' div there instead.")
  end

  if not any_dots then
    return blocks
  end

  local out = {}
  for gi, g in ipairs(groups) do
    if gi == 1 then
      for _, b in ipairs(g) do table.insert(out, b) end
    elseif #g > 0 then
      table.insert(out, pandoc.Div(g, pandoc.Attr("", { "fragment" }, {})))
    end
  end
  return out
end

-- Pass 1: handle dots nested inside any Pandoc div (columns, ::: wrappers,
-- etc.), innermost-first via Pandoc's normal bottom-up element walk.
local pass_divs = {
  Div = function(div)
    div.content = split_dots(div.content)
    return div
  end,
}

-- Pass 2: handle dots sitting directly at the top level of a slide (not
-- inside any div), segmented by slide boundaries (headers / horizontal rules).
local pass_top_level = {
  Pandoc = function(doc)
    local out = {}
    local seg = {}

    local function is_boundary(b)
      if b.t == "HorizontalRule" then return true end
      if b.t == "Header" and b.level <= 2 then return true end
      return false
    end

    local function flush()
      if #seg > 0 then
        local processed = split_dots(seg)
        for _, b in ipairs(processed) do table.insert(out, b) end
        seg = {}
      end
    end

    for _, b in ipairs(doc.blocks) do
      if is_boundary(b) then
        flush()
        table.insert(out, b)
      else
        table.insert(seg, b)
      end
    end
    flush()

    doc.blocks = out
    return doc
  end,
}

return { pass_divs, pass_top_level }
