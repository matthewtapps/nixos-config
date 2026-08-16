--!nonstrict
-- Opens straight into the shared text buffer. The header icons switch to the
-- device picker, the clipboard, a path entry, and the recovery list.

local view = "editor"
local buffer = ""
local editorRev = 0
local dirty = false
local idleTicks = 0
local doc = nil
local connected = false
local targets = {}
local history = {}
local pending = nil
local pathDraft = ""
local render

local function base()
  return `http://127.0.0.1:{noctalia.getConfig("syncd_port")}`
end

local function tr(key, subst)
  return noctalia.tr(key, subst)
end

local function queuePath()
  return `{noctalia.getenv("XDG_RUNTIME_DIR") or "/tmp"}/taildrop-queue`
end

local function splitNul(text)
  local out, start = {}, 1
  while true do
    local stop = text:find("\0", start, true)
    if not stop then
      local last = text:sub(start)
      if last ~= "" then
        table.insert(out, last)
      end
      return out
    end
    local piece = text:sub(start, stop - 1)
    if piece ~= "" then
      table.insert(out, piece)
    end
    start = stop + 1
  end
end

local function takeQueue()
  local contents = noctalia.readFile(queuePath())
  if not contents or contents == "" then
    return nil
  end
  local paths = splitNul(contents)
  return #paths > 0 and paths or nil
end

local function clearQueue()
  noctalia.writeFile(queuePath(), "")
end

local function request(payload)
  payload.nonce = noctalia.nowMs()
  noctalia.state.set("taildrop.request", payload)
end

local function flush()
  if not dirty then
    return
  end
  dirty = false
  local body = noctalia.json.encode({ text = buffer })
  if not body then
    return
  end
  noctalia.http({ url = `{base()}/doc`, method = "POST", body = body }, function() end)
end

local function basename(path)
  return path:match("[^/]+$") or path
end

local function statusLabel()
  if not connected then
    return tr("status.offline")
  end
  if dirty then
    return tr("status.editing")
  end
  return doc and doc.origin and tr("status.synced", { origin = doc.origin }) or tr("status.synced_plain")
end

local function iconButton(glyph, handler, tooltip)
  return ui.button({ glyph = glyph, variant = "ghost", onClick = handler, tooltip = tooltip })
end

local function header()
  local trailing
  if view == "editor" then
    trailing = {
      iconButton("send", "onPickTarget", tr("action.send_text")),
      iconButton("clipboard", "onPasteClipboard", tr("action.paste")),
      iconButton("file-plus", "onEnterPath", tr("action.send_path")),
      iconButton("history", "onShowHistory", tr("action.history")),
    }
  else
    trailing = { iconButton("arrow-left", "onBack", tr("action.back")) }
  end

  local children = {
    ui.glyph({ name = "send", color = connected and "primary" or "error" }),
    ui.label({ text = statusLabel(), fontSize = 11, color = "on_surface_variant" }),
    ui.spacer({ flexGrow = 1 }),
  }
  for _, node in ipairs(trailing) do
    table.insert(children, node)
  end
  return ui.row({ gap = 4, align = "center" }, children)
end

local function editorView()
  return ui.column({ flexGrow = 1, gap = 8, align = "stretch" }, {
    header(),
    ui.input({
      -- The rev reseeds the uncontrolled input when a peer's revision lands.
      key = `editor-{editorRev}`,
      value = buffer,
      multiline = true,
      focus = true,
      flexGrow = 1,
      placeholder = tr("editor.placeholder"),
      onChange = "onEdited",
    }),
  })
end

local function targetRow(target)
  local subtitle = pending and noctalia.trp("targets.files", #pending) or tr("targets.text")
  return ui.row({
    gap = 8,
    align = "center",
    padding = 8,
    radius = 8,
    fill = "surface_variant/0.4",
    key = target.name,
    onClick = function()
      if pending then
        request({ kind = "paths", paths = pending, target = target.name })
        clearQueue()
        pending = nil
      else
        request({ kind = "text", text = buffer, target = target.name })
      end
      panel.close()
    end,
  }, {
    ui.glyph({ name = "device-desktop", color = target.online and "primary" or "on_surface_variant" }),
    ui.column({ gap = 2, flexGrow = 1 }, {
      ui.label({ text = target.name, fontWeight = "bold" }),
      ui.label({ text = target.address, fontSize = 11, color = "on_surface_variant" }),
    }),
    ui.label({
      text = target.online and subtitle or tr("targets.offline"),
      fontSize = 11,
      color = "on_surface_variant",
    }),
  })
end

local function targetsView()
  local children = { header() }

  if pending then
    local names = {}
    for _, path in ipairs(pending) do
      table.insert(names, basename(path))
    end
    table.insert(children, ui.label({
      text = table.concat(names, ", "),
      fontSize = 11,
      color = "on_surface_variant",
    }))
  end

  local rows = {}
  for _, target in ipairs(targets) do
    table.insert(rows, targetRow(target))
  end
  if #rows == 0 then
    table.insert(rows, ui.label({ text = tr("targets.none"), color = "on_surface_variant" }))
  end
  table.insert(children, ui.scroll({ flexGrow = 1 }, { ui.column({ gap = 6, align = "stretch" }, rows) }))

  return ui.column({ flexGrow = 1, gap = 8, align = "stretch" }, children)
end

local function pathView()
  return ui.column({ flexGrow = 1, gap = 8, align = "stretch" }, {
    header(),
    ui.label({ text = tr("path.hint"), fontSize = 11, color = "on_surface_variant" }),
    ui.input({
      key = "path-entry",
      value = pathDraft,
      focus = true,
      placeholder = tr("path.placeholder"),
      onChange = "onPathChanged",
      onSubmit = "onPathSubmit",
    }),
    ui.spacer({ flexGrow = 1 }),
  })
end

local function historyView()
  local rows = {}
  for index, entry in ipairs(history) do
    local preview = entry.text:gsub("%s+", " ")
    if #preview > 90 then
      preview = preview:sub(1, 90) .. "..."
    end
    table.insert(rows, ui.row({
      gap = 8,
      align = "center",
      padding = 8,
      radius = 8,
      fill = "surface_variant/0.4",
      key = tostring(index),
      onClick = function()
        local body = noctalia.json.encode({ index = index - 1 })
        if body then
          noctalia.http({ url = `{base()}/restore`, method = "POST", body = body }, function()
            view = "editor"
            render()
          end)
        end
      end,
    }, {
      ui.label({ text = preview, fontSize = 12, flexGrow = 1 }),
      ui.label({ text = entry.origin or "", fontSize = 11, color = "on_surface_variant" }),
    }))
  end
  if #rows == 0 then
    table.insert(rows, ui.label({ text = tr("history.none"), color = "on_surface_variant" }))
  end

  return ui.column({ flexGrow = 1, gap = 8, align = "stretch" }, {
    header(),
    ui.scroll({ flexGrow = 1 }, { ui.column({ gap = 6, align = "stretch" }, rows) }),
  })
end

render = function()
  local tree
  if view == "targets" then
    tree = targetsView()
  elseif view == "path" then
    tree = pathView()
  elseif view == "history" then
    tree = historyView()
  else
    tree = editorView()
  end
  panel.render(ui.column({ flexGrow = 1, padding = 12 }, { tree }))
end

noctalia.state.watch("taildrop.doc", function(value)
  doc = value
  -- A remote revision never clobbers text being typed; it lands on the next
  -- clean moment instead.
  if value and not dirty and value.text ~= buffer then
    buffer = value.text
    editorRev += 1
  end
  render()
end)

noctalia.state.watch("taildrop.connected", function(value)
  connected = value == true
  render()
end)

noctalia.state.watch("taildrop.targets", function(value)
  targets = value or {}
  render()
end)

function onEdited(value)
  buffer = value
  dirty = true
  idleTicks = 0
end

function onPickTarget()
  flush()
  pending = nil
  view = "targets"
  request({ kind = "targets" })
  render()
end

function onPasteClipboard()
  local text = noctalia.clipboardText()
  if not text or text == "" then
    return
  end
  buffer = buffer ~= "" and `{buffer}\n{text}` or text
  dirty = true
  editorRev += 1
  flush()
  render()
end

function onEnterPath()
  pathDraft = ""
  view = "path"
  render()
end

function onPathChanged(value)
  pathDraft = value
end

function onPathSubmit(value)
  local path = noctalia.expandPath(noctalia.string.trim(value or pathDraft))
  if path == "" or not noctalia.fileExists(path) then
    noctalia.notifyError(tr("path.missing"), path)
    return
  end
  pending = { path }
  view = "targets"
  request({ kind = "targets" })
  render()
end

function onShowHistory()
  flush()
  view = "history"
  history = {}
  render()
  noctalia.http({ url = `{base()}/history` }, function(response)
    if response.ok and response.status == 200 then
      history = noctalia.json.decode(response.body) or {}
    end
    render()
  end)
end

function onBack()
  pending = nil
  view = "editor"
  render()
end

function onOpen(context)
  panel.setWantsSecondTicks(true)
  doc = noctalia.state.get("taildrop.doc")
  connected = noctalia.state.get("taildrop.connected") == true
  targets = noctalia.state.get("taildrop.targets") or {}
  if doc and not dirty then
    buffer = doc.text
    editorRev += 1
  end

  pending = context == "send" and takeQueue() or nil
  view = pending and "targets" or "editor"
  if pending then
    request({ kind = "targets" })
  end
  render()
end

function onClose()
  flush()
end

function update()
  if dirty then
    idleTicks += 1
    if idleTicks >= noctalia.getConfig("flush_idle_seconds") then
      flush()
      render()
    end
  end
end
