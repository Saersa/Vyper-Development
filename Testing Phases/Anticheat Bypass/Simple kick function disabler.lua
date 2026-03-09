local registry = getreg()

for i,v in pairs(registry) do
    if type(v) == "function" then
        local info = getinfo(v)
        if info.name == "kick" then
            hookfunction(info.func,function (...) return nil end)
            print("Blocked")
        end
    end
end