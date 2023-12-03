local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")
local insert_mode = require("multiple-cursors.insert_mode")

local mode_cmd = nil

-- Callback for the mode changed event
function M.mode_changed()

  -- Move the cursor after the mode has changed
  if mode_cmd == nil then
    return
  elseif mode_cmd == "a" then
    -- Shift cursors right
    virtual_cursors.move_with_normal_command("l", 0)
  elseif mode_cmd == "A" then
    -- Cursors to end of line
    virtual_cursors.move_with_normal_command("$", 0)
  elseif mode_cmd == "i" then
    -- curswant is lost
    virtual_cursors.visit_in_buffer(function(vc)
      vc.curswant = vc.col
    end)
  elseif mode_cmd == "I" then
    -- Cursor to start of line
    virtual_cursors.move_with_normal_command("^", 0)
  elseif mode_cmd == "o" then
    -- New line after current line
    virtual_cursors.move_with_normal_command("$", 0)
    insert_mode.all_virtual_cursors_carriage_return()
  elseif mode_cmd == "O" then
    -- New line before current line
    virtual_cursors.visit_in_buffer(function(vc)
      if vc.lnum == 1 then -- First line, move to start of line
        vc.col = 1
        vc.curswant = 1
      else -- Move to end of previous line
        vc.lnum = vc.lnum - 1
        vc.col = common.get_col(vc.lnum, vim.v.maxcol)
        vc.curswant = vim.v.maxcol
      end
    end)

    -- Carriage return
    virtual_cursors.edit_with_cursor(function(vc)
      -- If first line and first character
      if vc.lnum == 1 and vc.col == 1 then
        insert_mode.virtual_cursor_carriage_return(vc)
        vc.lnum = 1 -- Move the cursor back
      else
        insert_mode.virtual_cursor_carriage_return(vc)
      end
    end)
  elseif mode_cmd == "v" then

    local count = vim.v.count - 1

    virtual_cursors.visit_in_buffer(function(vc)

      -- Save cursor position as visual area start
      vc.visual_start_lnum = vc.lnum
      vc.visual_start_col = vc.col

      -- Move cursor forward if there's a count
      if count > 0 then
        vc.col = common.get_col(vc.lnum, vc.col + count)
        vc.curswant = vc.col
      end

    end)

  end

  mode_cmd = nil

end

function M.a()
  common.feedkeys("a", 0)
  mode_cmd = "a"
end

function M.A()
  common.feedkeys("A", 0)
  mode_cmd = "A"
end

function M.i() -- Also <Insert>
  common.feedkeys("i", 0)
  mode_cmd = "i"
end

function M.I()
  common.feedkeys("I", 0)
  mode_cmd = "I"
end

function M.o()
  common.feedkeys("o", 0)
  mode_cmd = "o"
end

function M.O()
  common.feedkeys("O", 0)
  mode_cmd = "O"
end

function M.v()
  common.feedkeys("v", vim.v.count)
  mode_cmd = "v"
end

return M
