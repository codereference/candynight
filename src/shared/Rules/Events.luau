-- Pure rules for limited-time events. An event can repeat every Nth night, be limited to a
-- date window, or both. The first matching event in catalog order wins.
-- catalog entries: { id, everyNthNight?, startsAt?, endsAt? (unix seconds), modifiers }
-- modifiers: { count?, health?, speed? (creature multipliers), reward? (income/bounty multiplier) }

local Events = {}

function Events.isActive(event, night: number, now: number): boolean
	if event.startsAt and now < event.startsAt then
		return false
	elseif event.endsAt and now >= event.endsAt then
		return false
	elseif event.everyNthNight and night % event.everyNthNight ~= 0 then
		return false
	end
	return true
end

-- The event running on this night, or nil.
function Events.forNight(catalog, night: number, now: number)
	for _, event in catalog do
		if Events.isActive(event, night, now) then
			return event
		end
	end
	return nil
end

return Events
