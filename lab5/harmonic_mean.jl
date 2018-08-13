@generated function harmonic_mean{T,N}(vals :: Vararg{T,N})
    #Core.println("Generating harmonic_mean for ", N, " arguments of type ", T)
    exp = foldl((acc, i) -> :($acc + (1/vals[$i])), :(0), 1:N)
    return :(N/$exp)
end

#==============================================================================#

function harmonic_mean_test()
    harmonic_mean(1,4,4)
    harmonic_mean(1,7,4)
    harmonic_mean(1.0,4.0,4.0)
    harmonic_mean(2.0,4.0,-4.0)
    harmonic_mean(2,3,5,7,60)
    harmonic_mean(60,7,5,3,2)
    harmonic_mean(2.f0,3.f0,5.f0,7.f0,60.f0)
    harmonic_mean(3.f0,7.f0,5.f0,7.f0,10.f0)
    harmonic_mean(1,4,4)
end

#harmonic_mean_test()
