Players = table(["abc";"dcd";"cdf"], cell(3,1),'VariableNames',{'Name','Role'})
Players.Role{1} = 'Cricketer'

Players.Role = repmat("",size(Players.Name))
Players(1,:) = {"sadas", "qwewq"}