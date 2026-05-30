---@meta
---@diagnostic disable:lowercase-global

---@param name string
---@param fn fun()
function describe(name, fn) end

---@param name string
---@param fn fun()
function it(name, fn) end

---@param fn fun()
function before_each(fn) end

---@param fn fun()
function after_each(fn) end

---@param fn fun()
function before_all(fn) end

---@param fn fun()
function after_all(fn) end

---@param reason? string
function pending(reason) end

---@type table
assert = assert

---@type table
spy = spy

---@type table
stub = stub

---@type table
mock = mock

---@type table
match = match
