-- Tiny helper for building Instances declaratively without pulling in a real
-- UI library. Returns the root so callers can parent it where they want.

local UIBuilder = {}

function UIBuilder.new(className, props, children)
	local inst = Instance.new(className)
	if props then
		for key, value in pairs(props) do
			if key ~= "Parent" then
				inst[key] = value
			end
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = inst
		end
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

function UIBuilder.corner(radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 6)
	return c
end

function UIBuilder.stroke(color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(0, 0, 0)
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return s
end

function UIBuilder.padding(top, right, bottom, left)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, top or 0)
	p.PaddingRight = UDim.new(0, right or top or 0)
	p.PaddingBottom = UDim.new(0, bottom or top or 0)
	p.PaddingLeft = UDim.new(0, left or right or top or 0)
	return p
end

function UIBuilder.gradient(from, to, rotation)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(from, to)
	g.Rotation = rotation or 90
	return g
end

return UIBuilder
