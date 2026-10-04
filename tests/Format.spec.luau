local t = require("./lib/t")
local Format = require("../src/shared/Format")

t.test("small amounts show in full", function()
	t.expect(Format.cash(0)).toBe("$0")
	t.expect(Format.cash(999)).toBe("$999")
end)

t.test("thousands and up use a short suffix", function()
	t.expect(Format.cash(1000)).toBe("$1K")
	t.expect(Format.cash(1250)).toBe("$1.2K")
	t.expect(Format.cash(3400000)).toBe("$3.4M")
	t.expect(Format.cash(7e9)).toBe("$7B")
end)

t.test("rounds down so it never overstates cash", function()
	t.expect(Format.cash(999999)).toBe("$999.9K")
	t.expect(Format.cash(12.9)).toBe("$12")
end)
