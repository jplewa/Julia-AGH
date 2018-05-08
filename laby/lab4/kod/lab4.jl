using DataFrames: DataFrame, vcat
using Gadfly: plot, draw, PNG, push_theme, set_default_plot_size, Geom, style, pt, cm
using CSV: write, read
using DifferentialEquations: @ode_def, ODEProblem, RK4, solve

# Napisać program rozwiązujący równania różniczkowe modelu Lotka-Volterra. (6 pkt):
lv = @ode_def LotkaVolterra begin
    dx = a*x - b*x*y
    dy = -c*y + d*x*y
end a b c d

#    Należy skorzystać z metod rozwiązywania równań różniczkowych zwyczajnych (ODE) oraz algorytmu Rungego-Kutty (RK4).
#    Program powinien umożliwiać uruchamianie dla różnych parametrów (a, b,c, d, warunki początkowe)
function get_solution_dataframe(parameters :: Array{Float64}, initial_conditions :: Array{Float64})
    tspan = (0.0, 30.0)
    problem = ODEProblem(lv, initial_conditions, tspan, parameters)
    solution = solve(problem, RK4(), dt=0.01)
    df :: DataFrame = DataFrame(time=solution.t, prey=map(x -> x[1], solution.u), predators=map(x -> x[2], solution.u))
end

#    Wynik programu powinien być zapisywany do pliku CSV.
function dataframe_into_cvs(exp_id :: String, df :: DataFrame)
    df[:experiment] = map(x -> exp_id, df[:time])
    CSV.write(string(exp_id, ".csv"), df)
end

# Wykonać serię eksperymentów dla różnych parametrów modelu L-V i wykonać analizę danych (6 pkt):
#    Należy wykonać co najmniej 4 eksperymenty dla różnych kombinacji parametrów.
function series_of_experiments(n :: Int64)
    rng = RandomDevice()
    map(i -> dataframe_into_cvs(string("exp", i), get_solution_dataframe(map(x -> x*5, rand(rng, 4)), map(x -> x*10, rand(rng, 2)))), 1:n)
end

#    Dla każdego eksperymentu wypisać minimalną, maksymalną oraz średnią liczbę drapieżników i ofiar.
function print_exp_stats(i :: Int64, df :: DataFrame)
    @printf("exp%d\t\t%f\t%f\t%f", i, minimum(df[:prey]), maximum(df[:prey]), mean(df[:prey]))
    @printf("\t%f\t%f\t%f\n", minimum(df[:predators]), maximum(df[:predators]), mean(df[:predators]))
end

#    Dane z wszystkich eksperymentów (pochodzące z osobnych plików CSV) należy umieścić w jednej tabeli (DataFrame).
#    Wyliczyć różnicę między liczbą drapieżników i ofiar jako nową kolumnę.
function combine_random_experiments(n :: Int64)
    series_of_experiments(n)
    dfs :: Array{DataFrame} = map(i -> CSV.read(string("exp", i, ".csv")), 1:n)
    @printf("experiment\tmin prey   \tmax prey\tavg prey\tmin predator\tmax predator\tavg predator\n")
    map(i -> print_exp_stats(i, dfs[i]), 1:n)
    combined_df :: DataFrame = foldl((acc, i) -> vcat(acc, dfs[i]), dfs[1], 2:n)
    combined_df[:difference] = map((x,y)-> (y-x), combined_df[:prey], combined_df[:predators])
    combined_df
end

# Narysować wykresy (8 pkt):
#    Grupę wykresów po jednym dla każdego eksperymentu, pokazujące zależności czasowe dla wszystkich kolumn danych (korzystając z Geom.subplot_grid).
#    Złożony wykres przestrzeni fazowej z nałożonymi seriami z wszystkich eksperymentów.
#    Na każdym wykresie należy umieścić podpisy osi oraz legendy, zawierające parametry eksperymentów.
function lab4_task(n :: Int64)
    df :: DataFrame = combine_random_experiments(n)
    Gadfly.push_theme(:dark)
    set_default_plot_size(30cm, 30cm)
    p = plot(df, x="prey", y="predators", color="experiment", Geom.point,
        style(major_label_font_size=14pt, minor_label_font_size=14pt))
    draw(PNG(string("phase_space.png"), 30cm, 30cm), p)
    df2 = vcat(DataFrame(time=df[:time], quantity=df[:prey], population="prey", experiment=df[:experiment]),
        DataFrame(time=df[:time], quantity=df[:predators], population="predators", experiment=df[:experiment]),
        DataFrame(time=df[:time], quantity=df[:difference], population="difference", experiment=df[:experiment]))
    p = plot(df2, ygroup="experiment", x="time", y="quantity", color="population",
        Geom.subplot_grid(Geom.line), style(major_label_font_size=14pt, minor_label_font_size=14pt))
    draw(PNG("population_over_time.png", 30cm, 30cm), p)
end

lab4_task(4)
