-- What follows is an implementation of a Needleman-Wunsch algorithm for
-- sequence alignment. It seems to be more widely known in context of
-- bioinformatics, where it is used to see how two DNA sequences are different
-- and how despite that they can be most optimally aligned. But for our problem
-- we compare characters and treat what they call gaps as insertions or
-- deletions, depending on the side. It seems to be quite similar to algorithms
-- for finding Levenshtein distance or Longest Common Subsequence.
--
-- One of the solutions to Longest Common Subsequence problem known as a "Myers
-- algorithm" is used in most diff tools (in particular, in xdiff lib, which is
-- used by Git and Vim/Neovim). But it's precision is sometimes not so great
-- for our case. Needleman-Wunsch is much more precise.
--
-- The complexity of Needleman-Wunsch algorithm is quadratic in both time and
-- space. That's why we use it's refined form, called "Hirschberg's algorithm"
-- in Wikipedia, which is still quadratic in time time, but linear in space.
-- And as Wikipedia says it is much faster in practice. Though in a linked
-- paper it's actually applied to Longest Common Subsequence problem. May be
-- there is another paper as well, but basically the same principle applies to
-- Needleman-Wunsch algorithm optimization anyway.
--
-- References
--   https://en.wikipedia.org/wiki/Needleman%E2%80%93Wunsch_algorithm
--   In form of a video: https://www.youtube.com/watch?v=ipp-pNRIp4g
--
--   https://en.wikipedia.org/wiki/Levenshtein_distance
--   https://en.wikipedia.org/wiki/Longest_common_subsequence
--   Myers algorithm paper: http://www.xmailserver.org/diff2.pdf
--
--   https://en.wikipedia.org/wiki/Hirschberg%27s_algorithm
--   Paper:
--   http://akira.ruc.dk/~keld/teaching/algoritmedesign_f03/Artikler/05/Hirschberg75.pdf

local util = require("format-on-save.util")

local function is_whitespace(s)
  return string.match(s, "^%s+$") ~= nil
end

local get_score = {
  ---@param x string
  ---@return integer
  del = function(x)
    if is_whitespace(x) then
      return -1
    else
      return -2
    end
  end,

  ---@param y string
  ---@return integer
  ins = function(y)
    if is_whitespace(y) then
      return -1
    else
      return -2
    end
  end,

  ---@param x string
  ---@param y string
  ---@return integer
  sub = function(x, y)
    if x == y then
      return 2
    else
      if is_whitespace(x) and is_whitespace(y) then
        return -1
      else
        return -2
      end
    end
  end,
}

---@param x string
---@param Y string[]
---@param prev_row number[]
---@param row_to_fill number[]
---@return nil
local function fill_nw_score_row(x, Y, prev_row, row_to_fill)
  row_to_fill[1] = prev_row[1] + get_score.del(x)

  for j = 2, #Y + 1 do
    local y = Y[j - 1]

    local score_sub = prev_row[j - 1] + get_score.sub(x, y)
    local score_del = prev_row[j] + get_score.del(x)
    local score_ins = row_to_fill[j - 1] + get_score.ins(y)

    row_to_fill[j] = math.max(score_sub, score_del, score_ins)
  end
end

local DELETE = 1
local INSERT = 2
local REPLACE = 3
local SKIP = 4

---@alias TextEdit `DELETE` | `INSERT` | `REPLACE` | `SKIP`

---@param X string[]
---@param Y string[]
---@return TextEdit[]
local function needleman_wunsch(X, Y)
  --- @type number[][]
  local score = { { 0 } }

  for j = 2, #Y + 1 do
    score[1][j] = score[1][j - 1] + get_score.ins(Y[j - 1])
  end

  for i = 2, #X + 1 do
    score[i] = {}
    fill_nw_score_row(X[i - 1], Y, score[i - 1], score[i])
  end

  ---@type TextEdit[]
  local text_edits = {}

  local i = #X + 1
  local j = #Y + 1
  while i > 1 or j > 1 do
    if i > 1 and j > 1 then
      local score_sub = score[i - 1][j - 1]
      local score_del = score[i - 1][j]
      local score_ins = score[i][j - 1]

      local max_score = math.max(score_sub, score_del, score_ins)

      if max_score == score_sub then
        if X[i - 1] == Y[j - 1] then
          text_edits[#text_edits + 1] = SKIP
        else
          text_edits[#text_edits + 1] = REPLACE
        end
        i = i - 1
        j = j - 1
      elseif max_score == score_ins then
        text_edits[#text_edits + 1] = INSERT
        j = j - 1
      else
        text_edits[#text_edits + 1] = DELETE
        i = i - 1
      end
    elseif j > 1 then
      text_edits[#text_edits + 1] = INSERT
      j = j - 1
    else
      text_edits[#text_edits + 1] = DELETE
      i = i - 1
    end
  end

  return util.list_reverse(text_edits)
end

---@param X string[]
---@param Y string[]
---@return number[]
local function nw_score(X, Y)
  --- @type number[][]
  local score = { { 0 }, {} }

  for j = 2, #Y + 1 do
    score[1][j] = score[1][j - 1] + get_score.ins(Y[j - 1])
  end

  for i = 2, #X + 1 do
    fill_nw_score_row(X[i - 1], Y, score[1], score[2])

    for j = 1, #Y + 1 do
      score[1][j] = score[2][j]
    end
  end

  return score[2]
end

---@param X string[]
---@param Y string[]
---@return TextEdit[]
local function hirschberg(X, Y)
  if #X == 0 then
    ---@type TextEdit[]
    local text_edits = {}

    for _ = 1, #Y do
      text_edits[#text_edits + 1] = INSERT
    end

    return text_edits
  elseif #Y == 0 then
    ---@type TextEdit[]
    local text_edits = {}

    for _ = 1, #X do
      text_edits[#text_edits + 1] = DELETE
    end

    return text_edits
  elseif #X == 1 or #Y == 1 then
    return needleman_wunsch(X, Y)
  else
    local xlen = #X
    local xmid = math.floor(xlen / 2)
    local ylen = #Y

    local score_l = nw_score(vim.list_slice(X, 1, xmid), Y)
    local score_r =
      nw_score(util.list_reverse(vim.list_slice(X, xmid + 1, xlen)), util.list_reverse(Y))

    local max_sum = score_l[1] + score_r[#score_r]
    local ymid = 1
    for i = 2, #score_l do
      local cur_sum = score_l[i] + score_r[#score_r - i + 1]

      if cur_sum > max_sum then
        ymid = i
        max_sum = cur_sum
      end
    end
    ymid = ymid - 1

    return vim.list_extend(
      hirschberg(vim.list_slice(X, 1, xmid), vim.list_slice(Y, 1, ymid)),
      hirschberg(vim.list_slice(X, xmid + 1, xlen), vim.list_slice(Y, ymid + 1, ylen))
    )
  end
end

---@param X string[]
---@param Y string[]
---@return VimDiffHunk[]
return function(X, Y)
  local edits = hirschberg(X, Y)

  local hunks = {}
  local k = 1
  local i = 0
  local j = 0
  while edits[k] do
    if edits[k] == SKIP then
      i = i + 1
      j = j + 1
      k = k + 1
    else
      local ds = i
      local dc = 0
      local as = j
      local ac = 0

      if edits[k] == REPLACE then
        ds = ds + 1
        as = as + 1

        repeat
          i = i + 1
          dc = dc + 1

          j = j + 1
          ac = ac + 1

          k = k + 1
        until not edits[k] or edits[k] ~= REPLACE
      elseif edits[k] == DELETE then
        ds = ds + 1

        repeat
          i = i + 1
          dc = dc + 1

          k = k + 1
        until not edits[k] or edits[k] ~= DELETE
      elseif edits[k] == INSERT then
        as = j + 1

        repeat
          j = j + 1
          ac = ac + 1

          k = k + 1
        until not edits[k] or edits[k] ~= INSERT
      end

      hunks[#hunks + 1] = { ds, dc, as, ac }
    end
  end

  return hunks
end
