# pochodna ze stałej
autodiff(f :: Number) = 0

# pochodna ze zmiennej
autodiff(f :: Symbol) = 1

# pochodna z sumy dowolnej liczby składników (suma pochodnych)
function autodiff( :: Type{Val{:+}}, args...) :: Expr
    Expr(:call, :+, map(y -> autodiff(y), args[1:end])...)
end

# pochodna z różnicy dwóch liczb (różnica pochodnych)
function autodiff( :: Type{Val{:-}}, args...) :: Expr
    Expr(:call, :-, autodiff(args[1]), autodiff(args[2]))
end

# pochodna z iloczynu dowolnej liczby czynników
# (pochodna z iloczynu ostatniego czynnika oraz iloczynu wszystkich czynników poprzedzających ostatni czynnik)
function autodiff( :: Type{Val{:*}}, args...) :: Expr
    g = (length(args) == 2) ? args[1] : Expr(:call, :*, args[1:end-1]...)
    h = args[end]
    Expr(:call, :+,
        Expr(:call, :*, h, autodiff(g)),
        Expr(:call, :*, autodiff(h), g))
end

# pochodna z ilorazu dwóch liczb
function autodiff( :: Type{Val{:/}}, args...) :: Expr
    g = args[1]
    h = args[2]
    Expr(:call, :/,
        Expr(:call, :-,
            Expr(:call, :*, autodiff(g), h),
            Expr(:call, :*, g, autodiff(h))),
        Expr(:call, :^, h, 2))
end

# metoda top-level
function autodiff(f :: Expr)
    autodiff(Val{f.args[1]}, f.args[2:end]...)
end

#==============================================================================#

function autodiff_test()
    f1 = :(x*x*(7/((((x/x)+(x*x*x)-(7*x*x/3)-(x/3))*x*x)/x)))
    df1 = autodiff(f1)
    println(eval(df1), " == -0.3063973...")   # Wolfram

    f2 = :(y/y/(y*y*(7/((((y/y)+(y*y*y)-(7*y*y/3)-(y/3))*y*y)/y))))
    df2 = autodiff(f2)
    println(eval(df2), " == -0.076330...")    # Wolfram

    f3 = :(7*z/z/z/z/(z*z*(7/((((z/z)+(z*z*z)-(7*z*z/3)-(z/3))*z*z)/z)))-13z)
    df3 = autodiff(f3)
    println(eval(df3), " == -12.9998...")     # Wolfram
end

x = 5
y = 1.23
z = 123.5

autodiff_test()

#==============================================================================#

# https://int8.io/automatic-differentiation-machine-learning-julia/

using DualNumbers
function autodiffFun(f) :: Function
   return x -> dualpart(f(Dual(x, 1)))
end

#==============================================================================#

function autodiffFun_test()
    f(x) = (x*x*(7/((((x/x)+(x*x*x)-(7*x*x/3)-(x/3))*x*x)/x)))
    g = autodiffFun(f)
    println(g(13), " == -0.008645...")        # Wolfram

    u(x) = x * x + x - 10
    v = autodiffFun(u)
    println(v(5), " == 11")                   # z opisu zadania
end

autodiffFun_test()
