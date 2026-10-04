-- Pure badge rules: which milestones a profile has reached that it hasn't been awarded yet.

local Badges = {}

-- Every badge and the condition that earns it, in display order.
Badges.ALL = {
	{
		key = "FirstSale",
		earned = function(p)
			return p.stats.served >= 1
		end,
	},
	{
		key = "FirstStaff",
		earned = function(p)
			return p.owned.Staff1 == true
		end,
	},
	{
		key = "FirstDefense",
		earned = function(p)
			return #p.placed >= 1
		end,
	},
	{
		key = "FirstNight",
		earned = function(p)
			return p.nightsSurvived >= 1
		end,
	},
	{
		key = "Streak5",
		earned = function(p)
			return p.bestStreak >= 5
		end,
	},
	{
		key = "Streak10",
		earned = function(p)
			return p.bestStreak >= 10
		end,
	},
	{
		key = "Streak25",
		earned = function(p)
			return p.bestStreak >= 25
		end,
	},
	{
		key = "Served1000",
		earned = function(p)
			return p.stats.served >= 1000
		end,
	},
	{
		key = "FirstRebirth",
		earned = function(p)
			return p.rebirths >= 1
		end,
	},
	{
		key = "Rebirth5",
		earned = function(p)
			return p.rebirths >= 5
		end,
	},
}

-- Marks newly reached badges on the profile and returns their keys (empty when nothing new).
function Badges.award(profile): { string }
	local new = {}
	for _, badge in Badges.ALL do
		if not profile.badges[badge.key] and badge.earned(profile) then
			profile.badges[badge.key] = true
			table.insert(new, badge.key)
		end
	end
	return new
end

return Badges
