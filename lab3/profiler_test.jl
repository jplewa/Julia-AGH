import Base.Random

function fun1()
    for i = 1:100000
        str = randstring(1)^10
    end
end


function fun2()
    for i = 1:10000
        str = randstring(1)^10
    end
end


function profiler_test()
    for i = 1:500
        fun1()
        fun2()
    end
end

profiler_test()

Profile.init(delay = 0.0001)
Profile.clear()
@profile profiler_test()
Profile.print(format=:flat)
# 21497 - fun1()
# 1997 - fun2()
using ProfileView
ProfileView.view()


Profile.init(delay = 0.001)
Profile.clear()
@profile profiler_test()
Profile.print(format=:flat)
# 14250 - fun1()
# 1374 - fun2()

Profile.init(delay = 0.01)
Profile.clear()
@profile profiler_test()
Profile.print(format=:flat)
# 1653 fun1()
# 152 fun2()

Profile.init(delay = 0.1)
Profile.clear()
@profile profiler_test()
Profile.print(format=:flat)
# 144 fun1()
# 16 fun2()

Profile.init(delay = 0.5)
Profile.clear()
@profile profiler_test()
Profile.print(format=:flat)
# 23 fun1()
# 4 fun2()
