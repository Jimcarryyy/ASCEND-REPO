local Smooth = "SmoothPlastic"

script.Parent.MouseButton1Click:Connect(function()
	if script.Parent.Text == "Low Graphics? (Permanent)" then
		script.Parent.Text = "Graphics - High"
		for i,v in pairs (workspace:GetDescendants()) do
			if v:IsA("Part") then
				local OldMat = Instance.new("StringValue",v)
				OldMat.Name = "Old_Material"
				OldMat.Value = tostring(v.Material)
				v.Material =  Smooth
			elseif
				script.Parent.Text == "Graphics - High" then
			      	script.Parent.Text = "Low Graphics? (Permanent)"
				    for i,v in pairs(workspace:GetDescendants()) do
				     	if v:IsA("BasePart") then
						    local OldMat1 = v:FindFirstChild("Old_Material")
					        if OldMat1 then
							    local Countme = #OldMat1.Value
							    local Getit = string.sub(OldMat1.Value,15,Countme)
							    v.Material = Getit
							    OldMat1:Destroy()
						    end
					    end
		            end
			end	
		end
	end
end)