local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

return {
	s(
		"dirt",
		fmt(
			[[
=== DIRT Loop ===
[INTENTION]
{}

[ACTION]
{}

[RESULT]
{}

[NEXT TIME]
{}
=================
]],
			{ i(1), i(2), i(3), i(4) }
		)
	),
	s("leet", {
		t({ "# 📘 Problem: [" }),
		i(1, "Problem Title"),
		t({ "](https://leetcode.com/problems/" }),
		i(2, "slug"),
		t({ ")" }),
		t({ "", "", "## 🧩 1. Problem Understanding", "- **Restate the problem in your own words:**", "  > " }),
		i(3),
		t({ "", "- **What are the constraints?**", "  - " }),
		i(4),
		t({ "", "- **What happens on edge cases?**", "  - " }),
		i(5),
		t({ "", "", "## 🔍 2. Pattern Recognition", "- **Have I seen a similar structure before?**", "  > " }),
		i(6),
		t({ "", "- **What category does this fall into?**", "  - " }),
		i(7),
		t({ "", "- **What’s a brute-force way to solve it?**", "  - " }),
		i(8),
		t({ "", "- **What would make that too slow?**", "  - " }),
		i(9),
		t({ "", "", "## ⚙️ 3. Strategy", "- **What data structures will I use?**", "  > " }),
		i(10),
		t({ "", "- **What’s my plan? Step by step:**", "  1. " }),
		i(11),
		t({ "", "  2. " }),
		i(12),
		t({ "", "  3. " }),
		i(13),
		t({ "", "- **Any optimization opportunities?**", "  - " }),
		i(14),
		t({ "", "", "## 💻 4. Implementation Notes", "- **What test cases will I use?**", "  - Normal case: " }),
		i(15),
		t({ "", "  - Edge case: " }),
		i(16),
		t({ "", "  - Stress case: " }),
		i(17),
		t({ "", "- **Where could bugs hide?**", "  - " }),
		i(18),
		t({ "", "", "## 🧠 5. Debugging / Mistakes (if any)", "- What didn’t work at first?", "  - " }),
		i(19),
		t({ "", "- Why didn’t it work?", "  - " }),
		i(20),
		t({ "", "- How did I fix it?", "  - " }),
		i(21),
		t({ "", "", "## 🎓 6. Final Reflections", "- **What pattern was this?**", "  - " }),
		i(22),
		t({ "", "- **What made it tricky?**", "  - " }),
		i(23),
		t({ "", "- **What was the key insight?**", "  - " }),
		i(24),
		t({ "", "- **What would I tell someone learning this problem?**", "  - " }),
		i(25),
		t({
			"",
			"",
			"## 🧪 7. Repetition Plan",
			"- [ ] Re-solve in 1 day",
			"- [ ] Re-solve in 3 days",
			"- [ ] Re-solve in 7 days",
		}),
	}),
}
