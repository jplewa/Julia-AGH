function poly_horner(x, a...)
    b=zero(x)
    for i= length(a):-1:1
        b= a[i] + b * x
    end
    return b
end

f_horner(x)=poly_horner(x,1,2,3,4,5)

f_horner(1)
using BenchmarkTools
@benchmark f_horner(3.5)
