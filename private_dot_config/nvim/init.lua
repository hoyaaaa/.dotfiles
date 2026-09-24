local last_im = nil
local focus_im = nil
local ENGLISH = "com.apple.keylayout.ABC"

-- im-select이 없으면 아무 것도 하지 않음 (일반 neovim/다른 OS 안전)
if vim.fn.executable("im-select") ~= 1 then
  return
end

local function current_im()
  local handle = io.popen("im-select")
  if not handle then return nil end
  local v = handle:read("*a")
  handle:close()
  if not v then return nil end
  return v:gsub("%s+", "")
end

local function set_im(id)
  if id and #id > 0 then
    os.execute("im-select " .. id)
  end
end

local function is_insert_mode()
  local m = vim.fn.mode()
  return m == "i" or m == "ic" or m == "ix"
end

-- Insert → Normal: 입력기 저장 + 영어 강제 + 스마트 줄번호(원하면 유지)
vim.api.nvim_create_autocmd("InsertLeave", {
  callback = function()
    last_im = current_im()
    set_im(ENGLISH)
    vim.opt.relativenumber = true
    vim.opt.number = true
  end,
})

-- Normal → Insert: 입력기 복원 + 스마트 줄번호
vim.api.nvim_create_autocmd("InsertEnter", {
  callback = function()
    if last_im and last_im ~= ENGLISH then
      set_im(last_im)
    end
    vim.opt.relativenumber = false
    vim.opt.number = true
  end,
})

-- 포커스 잃기: 직전 입력기 저장
vim.api.nvim_create_autocmd("FocusLost", {
  callback = function()
    focus_im = current_im()
  end,
})

-- 포커스 얻기: Insert 아니면 영어, Insert면 focus_im 복원
vim.api.nvim_create_autocmd("FocusGained", {
  callback = function()
    if not is_insert_mode() then
      set_im(ENGLISH)
    else
      if focus_im and focus_im ~= ENGLISH then
        set_im(focus_im)
      end
    end
  end,
})
