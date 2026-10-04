local t = require("./lib/t")
local Strings = require("../src/shared/Strings")

t.test("fills placeholders from variables", function()
	t.expect(Strings.get("Plot.Owned", { name = "Sep" })).toBe("Sep's Sweet Shop")
end)

t.test("leaves unknown placeholders visible", function()
	t.expect(Strings.get("Plot.Owned", {})).toBe("{name}'s Sweet Shop")
end)

t.test("unknown keys come back as the key", function()
	t.expect(Strings.get("Nope.Missing")).toBe("Nope.Missing")
end)

t.test("added strings can be looked up", function()
	Strings.add({ ["Test.Hello"] = "Hi {who}" })
	t.expect(Strings.get("Test.Hello", { who = "you" })).toBe("Hi you")
end)
