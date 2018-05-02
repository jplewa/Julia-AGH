function type_graph(my_type :: DataType)
    if my_type != Any
        string(type_graph(supertype(my_type)), " -> ", my_type)
    else
        string("Any")
    end
end

function fun(n)
    for i=1:n
        type_graph(Float64)
    end
end

println(type_graph(Float16))
println(type_graph(Int64))
println(type_graph(Any))

fun(1)
Profile.clear()
@profile fun(1000)
using ProfileView
ProfileView.view()
