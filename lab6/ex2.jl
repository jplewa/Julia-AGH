# number of consumers
consumers = 5

function producer(c :: Channel, rt :: String, extension :: String = "")
    for (root, dirs, files) in walkdir(rt, topdown=true, follow_symlinks=false, onerror=(x-> nothing))
        map(x -> endswith(x, extension) ? put!(c, joinpath(root, x)) : nothing, files)
        yield()
    end
    close(c)
end

# count of every consumer's lines
A = zeros(Int64, consumers)

function consumer(c :: Channel, id :: Int)
    for file in c
        n = length(readlines(file))
        println("<", id, "> ", file, " has ", n, " line(s)")
        A[id] += + n
        yield()
    end
end

@sync begin
    c = Channel(32)
    map(x -> (@async consumer(c, x)), 1:consumers)
    @async producer(c, "/home/julia/", ".txt")
end

println("All lines: ", sum(A))
