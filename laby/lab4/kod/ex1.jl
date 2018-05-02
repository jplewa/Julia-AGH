using DataFrames
using DifferentialEquations
using Gadfly
using CSV

lv = @ode_def LotkaVolterra begin
    dx = a*x - b*x*y
    dy = -c*y + d*x*y
end a b c d

function get_lv_dataframe(a,b,c,d,x0,y0)
    p =[a,b,c,d]
    u0 = [x0,y0]
    tspan = (0.0, 30.0)
    problem = ODEProblem(lv,u0,tspan,p)
    solution = solve(problem, RK4(), dt=0.01)
    df = DataFrame(t = solution.t, x = map(x -> x[1], solution.u), y = map(y -> y[2], solution.u))
    rename!(df, :x => :prey)
    rename!(df, :y => :predators)
    df
end

function experiment_into_csv(id :: String, a,b,c,d,x0,y0)
    df = get_lv_dataframe(a,b,c,d,x0,y0)
    df[:experiment] = map(x->id, df[:t])
    CSV.write(string(id, ".csv"), df)
end

function series_of_experiments(n :: Int64)
    rng = RandomDevice()
    for i=1:n
        experiment_into_csv(string("exp",i),rand(rng)*5,rand(rng)*5,rand(rng)*5,rand(rng)*5,rand(rng)*10,rand(rng)*10)
    end
end

function combine_experiments(n :: Int64)
    series_of_experiments(n)
    df = CSV.read(string("exp", 1, ".csv"))
    @printf("experiment\tmin prey   \tmax prey\tavg prey\tmin predator\tmax predator\tavg predator\n")
    @printf("exp %d\t\t%f\t%f\t%f", 1, minimum(df[:prey]), maximum(df[:prey]), sum(df[:prey])/length(df[:prey]))
    @printf("\t%f\t\t%f\t\t%f\n", minimum(df[:predators]), maximum(df[:predators]), sum(df[:predators])/length(df[:predators]))
    for i=2:n
        new_df = CSV.read(string("exp", i, ".csv"))
        @printf("exp %d\t\t%f\t%f\t%f", i, minimum(new_df[:prey]), maximum(new_df[:prey]), sum(new_df[:prey])/length(new_df[:prey]))
        @printf("\t%f\t\t%f\t\t%f\n", minimum(new_df[:predators]), maximum(new_df[:predators]), sum(new_df[:predators])/length(new_df[:predators]))
        df = vcat(df, new_df)
    end
    df[:difference] = map((x,y)-> (y-x), df[:prey], df[:predators])
    df
end

function lab4_task(n :: Int64)
    df = combine_experiments(n)
    set_default_plot_size(30cm, 30cm)
    p=plot(df, x="prey",y="predators", color="experiment", Geom.point,style(major_label_font_size=14pt,minor_label_font_size=14pt))
    draw(PNG(string("phase_space.png"), 30cm, 30cm),p)
    df1 = DataFrame(t=df[:t], n=df[:prey], population="prey", experiment=df[:experiment])
    df2 = DataFrame(t=df[:t], n=df[:predators], population="predators", experiment=df[:experiment])
    df3 = DataFrame(t=df[:t], n=df[:difference], population="difference", experiment=df[:experiment])
    df = vcat(df1, df2, df3)
    p = plot(df, ygroup="experiment", x="t", y="n", color="population",
             Geom.subplot_grid(Geom.line),style(major_label_font_size=14pt,minor_label_font_size=14pt))
    draw(PNG("population_over_time.png", 30cm, 30cm), p)
end

lab4_task(4)
